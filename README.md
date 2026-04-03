# NHS Prescribing Data Pipeline

A production-grade data pipeline built with AWS and Terraform, processing 18 million rows of NHS prescribing data monthly using Medallion Architecture.

## Architecture

```
EventBridge (monthly schedule)
      ↓
Lambda (trigger)
      ↓
Glue Workflow
  ├── Job 0: API → Bronze (18M rows from NHS CKAN API)
  ├── Crawler: Schema detection
  ├── Job 1: Bronze → Silver (cleaning & standardisation)
  └── Job 2: Silver → Gold (aggregation)
      ↓
Athena (SQL query engine)
      ↓
Streamlit Dashboard (coming soon)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Infrastructure | Terraform (IaC) |
| Orchestration | AWS Glue Workflow |
| Data Ingestion | AWS Lambda + NHS CKAN API |
| Data Processing | AWS Glue (PySpark) |
| Storage | AWS S3 (Medallion Architecture) |
| Query Engine | AWS Athena |
| Scheduling | AWS EventBridge |
| Security | AWS IAM (least privilege) |

## Data Layers

| Layer | Description | Format |
|-------|-------------|--------|
| Bronze | Raw data from NHS API | Parquet (181 batches) |
| Silver | Cleaned & standardised | Parquet (partitioned by year/month) |
| Gold | Aggregated analytics tables | Parquet (3 tables) |

## Gold Tables

- `practice_summary` - Total cost & items per GP Practice
- `drug_summary` - National prescribing volumes per drug
- `regional_trend` - Prescribing trends by region

## AWS Certifications

- AWS Certified Data Analytics - Specialty
- AWS Certified DevOps Engineer - Professional
- AWS Certified Database - Specialty

## Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.0
- Python 3.11
- AWS CLI configured with appropriate profile

## Setup

```bash
# Clone repo
git clone https://github.com/chipsopenclaw-project/nhs-prescribing-pipeline.git
cd nhs-prescribing-pipeline

# Create Terraform state bucket (one-time only)
aws s3 mb s3://ukb-dev-euw2-s3-tf-state --region eu-west-2 --profile terraform

# Initialise Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

## Project Structure

```
nhs-prescribing-pipeline/
├── main.tf                          # Root Terraform config
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── .gitignore
├── lambda_src/                      # Python scripts
│   ├── handler.py                   # Lambda - triggers Glue Workflow
│   ├── glue_api_to_bronze.py        # Fetches NHS data from CKAN API
│   ├── glue_bronze_to_silver.py     # Cleans and standardises data
│   └── glue_silver_to_gold.py       # Aggregates data into Gold tables
└── modules/
    ├── s3/                          # 5 S3 buckets (bronze/silver/gold/scripts/athena)
    ├── iam/                         # IAM roles and policies (least privilege)
    ├── lambda/                      # Lambda function
    ├── eventbridge/                 # Monthly schedule trigger
    ├── glue/                        # Glue jobs, crawler, workflow
    └── athena/                      # Athena workgroup and named queries
```

## Naming Convention

All resources follow UK Biobank naming standard:

```
ukb-{env}-euw2-{resource}-{purpose}

Examples:
  ukb-dev-euw2-s3-nhs-bronze
  ukb-dev-euw2-lambda-nhs-fetcher
  ukb-dev-euw2-glue-nhs-api-to-bronze
```

## Pipeline Flow

```
1. EventBridge triggers Lambda monthly (1st of each month, 6am UTC)
2. Lambda calls glue:StartWorkflowRun to trigger Glue Workflow
3. Glue Job 0 (api_to_bronze):
   - Calls NHS CKAN API with pagination (100,000 rows per batch)
   - 181 batches for 18M rows
   - Writes Parquet files to S3 Bronze
4. Glue Crawler scans Bronze bucket and updates Glue Catalog
5. Glue Job 1 (bronze_to_silver):
   - Reads Parquet from Bronze
   - Removes duplicates
   - Handles null values
   - Filters invalid records
   - Partitions by year/month
   - Writes to S3 Silver
6. Glue Job 2 (silver_to_gold):
   - Reads Silver Parquet
   - Aggregates into 3 Gold tables
   - Writes to S3 Gold
7. Athena queries Gold tables for Streamlit dashboard
```

## Security

- All S3 buckets have public access blocked
- Encryption at rest (AES256) on all data buckets
- IAM roles follow least privilege principle
- Lambda only has write access to Bronze bucket
- Glue roles scoped to specific buckets only
- Terraform state stored in S3 with versioning

## Cost Estimate

Running once per month (dev environment):

| Service | Estimated Cost |
|---------|---------------|
| Lambda | ~£0.01 |
| Glue Jobs (x3) | ~£1.50 |
| S3 Storage | ~£0.05/month |
| Athena Queries | ~£0.01 |
| **Total** | **~£1.57/month** |

## Roadmap

- [ ] Streamlit dashboard connected to Athena
- [ ] Unit tests with pytest and moto
- [ ] CI/CD with GitHub Actions
- [ ] CloudWatch alarms for pipeline monitoring
- [ ] Multi-month historical data loading
