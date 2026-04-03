# =============================================
# glue_api_to_bronze.py
# Fetches NHS Prescribing data from CKAN API
# Writes paginated data to S3 Bronze as Parquet
# =============================================

import sys
import json
import boto3
import requests
import pandas as pd
import io
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, [
    "JOB_NAME",
    "BRONZE_BUCKET",
    "API_BASE_URL",
    "RESOURCE_ID"
])

sc          = SparkContext()
glueContext = GlueContext(sc)
spark       = glueContext.spark_session
job         = Job(glueContext)
job.init(args["JOB_NAME"], args)

s3_client    = boto3.client("s3")
API_BASE_URL = args["API_BASE_URL"]
RESOURCE_ID  = args["RESOURCE_ID"]
BRONZE_BUCKET = args["BRONZE_BUCKET"]
BATCH_SIZE   = 100000

print(f"Starting API to Bronze job")
print(f"Resource ID: {RESOURCE_ID}")
print(f"Batch size: {BATCH_SIZE}")

def fetch_batch(offset: int) -> list:
    """
    Fetches one batch of records from CKAN API
    """
    url = f"{API_BASE_URL}/datastore_search"
    params = {
        "resource_id": RESOURCE_ID,
        "limit"      : BATCH_SIZE,
        "offset"     : offset
    }
    response = requests.get(url, params=params, timeout=60)
    response.raise_for_status()
    data = response.json()
    return data["result"]["records"]


def upload_batch_to_s3(records: list, batch_num: int) -> str:
    """
    Converts batch to Parquet and uploads to S3 Bronze
    """
    df     = pd.DataFrame(records)
    buffer = io.BytesIO()
    df.to_parquet(buffer, index=False, engine="pyarrow")
    buffer.seek(0)

    s3_key = f"prescribing/bronze/{RESOURCE_ID}/batch_{batch_num:04d}.parquet"
    s3_client.put_object(
        Bucket=BRONZE_BUCKET,
        Key=s3_key,
        Body=buffer.getvalue(),
        ContentType="application/octet-stream"
    )
    print(f"Batch {batch_num} uploaded: s3://{BRONZE_BUCKET}/{s3_key}")
    return s3_key


# Fetch total count
total_url    = f"{API_BASE_URL}/datastore_search"
total_params = {"resource_id": RESOURCE_ID, "limit": 1, "include_total": "true"}
total_resp   = requests.get(total_url, params=total_params, timeout=30)
total_rows   = total_resp.json()["result"]["total"]

print(f"Total rows to fetch: {total_rows:,}")

# Paginate through all records
offset    = 0
batch_num = 0

while offset < total_rows:
    print(f"Fetching batch {batch_num} (offset: {offset:,})")
    records = fetch_batch(offset)

    if not records:
        break

    upload_batch_to_s3(records, batch_num)

    offset    += BATCH_SIZE
    batch_num += 1

print(f"API to Bronze complete: {batch_num} batches, {total_rows:,} rows")

job.commit()
