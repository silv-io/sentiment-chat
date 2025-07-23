import os
import json
import redis
import boto3

# Initialize clients
verified_permissions = boto3.client('verifiedpermissions')
memorydb_host = os.environ['MEMORYDB_HOST']
policy_store_id = os.environ['POLICY_STORE_ID']

# Connect to MemoryDB
r = redis.Redis(host=memorydb_host, port=6379, ssl=True, ssl_cert_reqs=None)

def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    user_id = event['queryStringParameters']['userId']

    # Authorize with Verified Permissions
    try:
        response = verified_permissions.is_authorized(
            policyStoreId=policy_store_id,
            principal={
                'entityType': 'sentiment-chat::User',
                'entityId': user_id
            },
            action={
                'actionType': 'sentiment-chat::Action',
                'actionId': 'connect'
            },
            resource={
                'entityType': 'sentiment-chat::Application',
                'entityId': 'sentiment-chat'
            }
        )

        if response['decision'] != 'ALLOW':
            return {'statusCode': 403, 'body': 'Forbidden'}

    except Exception as e:
        print(e)
        return {'statusCode': 500, 'body': 'Internal server error'}

    # Store connection
    r.set(f"connection:{connection_id}", user_id)
    r.sadd("connections", connection_id)

    return {'statusCode': 200, 'body': 'Connected.'}
