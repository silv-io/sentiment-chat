import os
import redis

# Connect to MemoryDB
memorydb_host = os.environ['MEMORYDB_HOST']
r = redis.Redis(host=memorydb_host, port=6379, ssl=True, ssl_cert_reqs=None)

def handler(event, context):
    connection_id = event['requestContext']['connectionId']

    # Remove connection
    r.delete(f"connection:{connection_id}")
    r.srem("connections", connection_id)

    return {'statusCode': 200, 'body': 'Disconnected.'}
