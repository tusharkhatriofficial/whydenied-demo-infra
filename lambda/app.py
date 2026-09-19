import os
from urllib.parse import urlparse

import boto3

ssm = boto3.client("ssm")


def handler(event, context):
    # Fails with AccessDenied until the role is allowed ssm:GetParameter.
    param = ssm.get_parameter(Name=os.environ["DB_URL_PARAM"])
    db_url = urlparse(param["Parameter"]["Value"])
    return {"status": "ok", "db_host": db_url.hostname}
