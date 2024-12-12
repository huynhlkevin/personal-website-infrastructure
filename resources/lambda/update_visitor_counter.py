import boto3
import json
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["visitor_table_name"])

def lambda_handler(event, context):
    if event.httpMethod == "POST":
        if visitorCounterExists():
            incrementVisitorCounterValue()
        else:
            createVisitorCounterItem()
        return {
            "statusCode": 200,
            "headers": createHeaders(event),
            "body": json.dumps({
                "message": "Successfully updated visitor count.",
                "data": int(getVisitorCounterValue())
            })
        }
    else:
        return {
            "statusCode": 200,
            "headers": createHeaders(event),
            "body": json.dumps({
                "message": "Successfully retrieved visitor count.",
                "data": int(getVisitorCounterValue())
            })
        }


def createHeaders(event):
    return {
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Origin": os.environ["access_control_allow_origin"],
        "Access-Control-Allow-Methods": event.httpMethod
    }

def visitorCounterExists():
    response = table.get_item(Key = { "key": "count" })
    return "Item" in response

def createVisitorCounterItem():
    table.put_item(Item = {
        "key": "count",
        "val": 1
    })

def incrementVisitorCounterValue():
    table.update_item(
        Key = { "key": "count" },
        UpdateExpression = "SET val = val + :inc",
        ExpressionAttributeValues = { ":inc": 1 }
    )

def getVisitorCounterValue():
    return table.get_item(Key = { "key": "count" })["Item"]["val"]