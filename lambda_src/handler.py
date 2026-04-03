import os
import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

glue_client   = boto3.client("glue")
WORKFLOW_NAME = os.environ["GLUE_WORKFLOW_NAME"]


def lambda_handler(event, context):
    """
    Lightweight Lambda - only triggers Glue Workflow
    All data fetching is handled by Glue Job
    """
    logger.info("NHS Prescribing Pipeline Lambda started")

    try:
        response = glue_client.start_workflow_run(
            Name=WORKFLOW_NAME
        )

        run_id = response["RunId"]
        logger.info(f"Glue Workflow triggered: {WORKFLOW_NAME}")
        logger.info(f"Workflow Run ID: {run_id}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message"    : "Glue Workflow triggered successfully",
                "workflow"   : WORKFLOW_NAME,
                "run_id"     : run_id
            })
        }

    except Exception as e:
        logger.error(f"Failed to trigger Glue Workflow: {str(e)}")
        raise
