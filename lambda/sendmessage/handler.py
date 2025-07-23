import os
import json
import redis
import boto3
from botocore.exceptions import ClientError

# Initialize clients
bedrock = boto3.client('bedrock-runtime')
sns = boto3.client('sns')
verified_permissions = boto3.client('verified-permissions')
apigatewaymanagementapi = boto3.client('apigatewaymanagementapi', endpoint_url=f"https://{os.environ['API_GATEWAY_ID']}.execute-api.{os.environ['AWS_REGION']}.amazonaws.com/{os.environ['API_GATEWAY_STAGE']}")

# Environment variables
memorydb_host = os.environ['MEMORYDB_HOST']
bedrock_model_id = os.environ['BEDROCK_MODEL_ID']
sns_topic_arn = os.environ['SNS_TOPIC_ARN']
policy_store_id = os.environ['POLICY_STORE_ID']
negative_sentiment_threshold = float(os.environ['NEGATIVE_SENTIMENT_THRESHOLD'])

# Connect to MemoryDB
r = redis.Redis(host=memorydb_host, port=6379, ssl=True, ssl_cert_reqs=None)

def get_sentiment(text):
    prompt = f"Human: Please analyze the sentiment of this text and return a score between -1 (very negative) and 1 (very positive). Text: {text}\n\nAssistant:"
    body = json.dumps({
        "prompt": prompt,
        "max_tokens_to_sample": 5,
        "temperature": 0.1,
        "top_p": 0.9,
    })
    response = bedrock.invoke_model(body=body, modelId=bedrock_model_id)
    response_body = json.loads(response.get('body').read())
    return float(response_body['completion'])

def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    message_body = json.loads(event['body'])
    message = message_body['message']

    user_id = r.get(f"connection:{connection_id}").decode('utf-8')

    # Authorize with Verified Permissions
    try:
        response = verified_permissions.is_authorized(
            policyStoreId=policy_store_id,
            principal={'entityType': 'sentiment-chat::User', 'entityId': user_id},
            action={'actionType': 'sentiment-chat::Action', 'actionId': 'sendMessage'},
            resource={'entityType': 'sentiment-chat::Application', 'entityId': 'sentiment-chat'}
        )
        if response['decision'] != 'ALLOW':
            return {'statusCode': 403, 'body': 'Forbidden'}
    except ClientError as e:
        print(e)
        return {'statusCode': 500, 'body': 'Internal server error'}

    # Get sentiment
    try:
        sentiment_score = get_sentiment(message)
    except ClientError as e:
        print(e)
        return {'statusCode': 500, 'body': 'Failed to analyze sentiment.'}

    # Check for negative sentiment
    if sentiment_score < negative_sentiment_threshold:
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps({'user': user_id, 'message': message, 'sentiment': sentiment_score}),
            Subject='Negative Sentiment Detected'
        )

    # Store message
    r.rpush(f"session:{user_id}", json.dumps({'message': message, 'sentiment': sentiment_score}))
    r.ltrim(f"session:{user_id}", -10, -1) # Keep last 10 messages

    # Broadcast message
    all_connections = r.smembers("connections")
    payload = json.dumps({'user': user_id, 'message': message, 'sentiment': sentiment_score})

    for conn_id in all_connections:
        try:
            apigatewaymanagementapi.post_to_connection(ConnectionId=conn_id.decode('utf-8'), Data=payload)
        except ClientError as e:
            # If the connection is gone, remove it from our list
            if e.response['Error']['Code'] == 'GoneException':
                r.srem("connections", conn_id)

    return {'statusCode': 200, 'body': 'Message sent.'}