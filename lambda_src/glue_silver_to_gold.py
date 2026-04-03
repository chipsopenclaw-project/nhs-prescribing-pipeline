# =============================================
# glue_silver_to_gold.py
# Silver -> Gold aggregation:
#   - Total cost per GP Practice
#   - Total prescriptions per drug nationally
#   - Prescribing trend per region
# =============================================

import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "SILVER_BUCKET",
    "GOLD_BUCKET"
])

sc          = SparkContext()
glueContext = GlueContext(sc)
spark       = glueContext.spark_session
job         = Job(glueContext)
job.init(args["JOB_NAME"], args)

print(f"Starting Silver to Gold job")
print(f"Reading from: s3://{args['SILVER_BUCKET']}/prescribing/silver/")

# Read silver Parquet
silver_df = spark.read.parquet(
    f"s3://{args['SILVER_BUCKET']}/prescribing/silver/"
)

print(f"Silver rows loaded: {silver_df.count()}")

# ---------------------------
# Gold Table 1: Total cost per GP Practice
# ---------------------------
practice_df = silver_df \
    .groupBy("practice_code", "practice_name", "year", "month") \
    .agg(
        F.sum("actual_cost").alias("total_cost"),
        F.sum("items").alias("total_items"),
        F.sum("nic").alias("total_nic"),
        F.round(
            F.sum("actual_cost") / F.sum("items"), 2
        ).alias("avg_cost_per_item")
    ) \
    .withColumn("gold_processed_at", F.current_timestamp())

practice_df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(f"s3://{args['GOLD_BUCKET']}/prescribing/gold/practice_summary/")

print(f"Gold Table 1 written: practice_summary")

# ---------------------------
# Gold Table 2: Total prescriptions per drug nationally
# ---------------------------
drug_df = silver_df \
    .groupBy("bnf_code", "bnf_description", "year", "month") \
    .agg(
        F.sum("items").alias("total_items"),
        F.sum("actual_cost").alias("total_cost"),
        F.sum("nic").alias("total_nic"),
        F.countDistinct("practice_code").alias("num_practices")
    ) \
    .withColumn("gold_processed_at", F.current_timestamp())

drug_df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(f"s3://{args['GOLD_BUCKET']}/prescribing/gold/drug_summary/")

print(f"Gold Table 2 written: drug_summary")

# ---------------------------
# Gold Table 3: Prescribing trend per region
# ---------------------------
regional_df = silver_df \
    .groupBy("regional_office_name", "year", "month") \
    .agg(
        F.sum("items").alias("total_items"),
        F.sum("actual_cost").alias("total_cost"),
        F.countDistinct("practice_code").alias("num_practices"),
        F.round(
            F.sum("actual_cost") / F.countDistinct("practice_code"), 2
        ).alias("avg_cost_per_practice")
    ) \
    .withColumn("gold_processed_at", F.current_timestamp())

regional_df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(f"s3://{args['GOLD_BUCKET']}/prescribing/gold/regional_trend/")

print(f"Gold Table 3 written: regional_trend")

job.commit()
print("Silver to Gold job completed successfully")
