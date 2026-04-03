# =============================================
# tests/test_handler.py
# Unit tests for Lambda handler
# =============================================

import os
import json
import pytest
from unittest.mock import patch, MagicMock

os.environ["BRONZE_BUCKET_NAME"]  = "test-bronze-bucket"
os.environ["NHS_API_BASE_URL"]    = "https://opendata.nhsbsa.net/api/3/action"
os.environ["NHS_DATASET_ID"]      = "english-prescribing-data-epd"
os.environ["GLUE_WORKFLOW_NAME"]  = "test-workflow"

from lambda_src.handler import lambda_handler


# ---------------------------
# Tests: lambda_handler
# ---------------------------

def test_lambda_handler_triggers_workflow_successfully():
    """Should trigger Glue Workflow and return 200"""
    with patch("lambda_src.handler.glue_client.start_workflow_run") as mock_glue:
        mock_glue.return_value = {"RunId": "test-run-id-123"}

        result = lambda_handler({}, {})

        assert result["statusCode"] == 200
        body = json.loads(result["body"])
        assert body["message"]  == "Glue Workflow triggered successfully"
        assert body["workflow"] == "test-workflow"
        assert body["run_id"]   == "test-run-id-123"
        mock_glue.assert_called_once_with(Name="test-workflow")


def test_lambda_handler_raises_on_glue_failure():
    """Should raise exception if Glue trigger fails"""
    with patch("lambda_src.handler.glue_client.start_workflow_run") as mock_glue:
        mock_glue.side_effect = Exception("Glue Error")

        with pytest.raises(Exception, match="Glue Error"):
            lambda_handler({}, {})


def test_lambda_handler_returns_workflow_name():
    """Should return correct workflow name in response"""
    with patch("lambda_src.handler.glue_client.start_workflow_run") as mock_glue:
        mock_glue.return_value = {"RunId": "run-456"}

        result = lambda_handler({}, {})
        body   = json.loads(result["body"])

        assert body["workflow"] == "test-workflow"


def test_lambda_handler_returns_run_id():
    """Should return run_id from Glue response"""
    with patch("lambda_src.handler.glue_client.start_workflow_run") as mock_glue:
        mock_glue.return_value = {"RunId": "run-789"}

        result = lambda_handler({}, {})
        body   = json.loads(result["body"])

        assert body["run_id"] == "run-789"
