import boto3
import os
import json
from datetime import datetime

s3 = boto3.client("s3")
bucket_name = os.environ.get("BUCKET_NAME")

def lambda_handler(event, context):
    try:
        now = datetime.utcnow().isoformat()
        key = f"lambda-output/{now}.json"
        body = {"message": "Hello from Lambda!", "timestamp": now}

        s3.put_object(Bucket=bucket_name, Key=key, Body=json.dumps(body))

        return {
            "statusCode": 200,
            "body": json.dumps({"message": f"File saved to {bucket_name}/{key}"})
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
