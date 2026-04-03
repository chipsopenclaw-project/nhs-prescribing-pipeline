# =============================================
# glue_bronze_to_silver.py
# Bronze -> Silver transformation
# =============================================

import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "BRONZE_BUCKET",
    "SILVER_BUCKET"
])

sc          = SparkContext()
glueContext = GlueContext(sc)
spark       = glueContext.spark_session
job         = Job(glueContext)
job.init(args["JOB_NAME"], args)

print(f"Starting Bronze to Silver job")
print(f"Reading from: s3://{args['BRONZE_BUCKET']}/prescribing/bronze/EPD_*/")

# ---------------------------
# Step 1: Read Parquet from bronze bucket
# ---------------------------
raw_df = spark.read \
    .parquet(f"s3://{args['BRONZE_BUCKET']}/prescribing/bronze/EPD_*/")

print(f"Bronze rows loaded: {raw_df.count()}")
print(f"Columns: {raw_df.columns}")

# ---------------------------
# Step 2: Standardise column names
# lowercase + replace spaces with underscores
# ---------------------------
cleaned_df = raw_df
for col_name in raw_df.columns:
    clean_name = col_name.lower() \
        .replace(" ", "_") \
        .replace("-", "_") \
        .strip()
    cleaned_df = cleaned_df.withColumnRenamed(col_name, clean_name)

print("Column names standardised")

# ---------------------------
# Step 3: Remove duplicate rows
# ---------------------------
deduped_df = cleaned_df.dropDuplicates()
print(f"Duplicate rows removed: {raw_df.count() - deduped_df.count()}")

# ---------------------------
# Step 4: Handle null values
# ---------------------------
filled_df = deduped_df \
    .fillna({"items": 0, "nic": 0.0, "actual_cost": 0.0})

critical_columns = ["bnf_code", "bnf_description", "year_month"]
filtered_df = filled_df.dropna(subset=critical_columns)
print(f"Null rows removed: {deduped_df.count() - filtered_df.count()}")

# ---------------------------
# Step 5: Filter invalid data
# ---------------------------
valid_df = filtered_df \
    .filter(F.col("items") > 0) \
    .filter(F.col("nic") >= 0) \
    .filter(F.col("actual_cost") >= 0)

print(f"Invalid rows removed: {filtered_df.count() - valid_df.count()}")

# ---------------------------
# Step 6: Add metadata + partition columns
# year_month format: 202506 -> year=2025, month=6
# ---------------------------
silver_df = valid_df \
    .withColumn("silver_processed_at", F.current_timestamp()) \
    .withColumn("source", F.lit("nhs_bsa_prescribing_api")) \
    .withColumn("year",
        F.col("year_month").cast("string").substr(1, 4).cast("int")
    ) \
    .withColumn("month",
        F.col("year_month").cast("string").substr(5, 2).cast("int")
    )

print(f"Silver rows ready: {silver_df.count()}")

# ---------------------------
# Step 7: Write to silver bucket as Parquet
# ---------------------------
output_path = f"s3://{args['SILVER_BUCKET']}/prescribing/silver/"

silver_df.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(output_path)

print(f"Silver Parquet written to: {output_path}")

job.commit()
print("Bronze to Silver job completed successfully")
