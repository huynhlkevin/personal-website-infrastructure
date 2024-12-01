import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("visitor")

def lambda_handler(event, context):

    if visitorCounterExists():
        incrementVisitorCounterValue()
    else:
        createVisitorCounterItem()

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "https://www.huynhlkevin.com",
            "Access-Control-Allow-Methods": "POST"
        },
        "body": json.dumps({
            "message": "Successfully updated visitor count.",
            "data": int(getVisitorCounterValue())
        })
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