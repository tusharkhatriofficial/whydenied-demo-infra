import os
from urllib.parse import urlparse

import boto3

ssm = boto3.client("ssm")


def handler(event, context):
    # {"mode": "list"} reads every setting under the app's prefix, which needs a
    # second permission. Anything else reads the database URL only.
    if (event or {}).get("mode") == "list":
        page = ssm.get_parameters_by_path(Path=os.environ["CONFIG_PREFIX"])
        return {"status": "ok", "settings": [p["Name"] for p in page["Parameters"]]}

    # Fails with AccessDenied until the role is allowed ssm:GetParameter.
    param = ssm.get_parameter(Name=os.environ["DB_URL_PARAM"])
    db_url = urlparse(param["Parameter"]["Value"])
    return {"status": "ok", "db_host": db_url.hostname}
