import json
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def handler(event, context):
    """
    Lambda function handler for processing S3 events.
    
    Args:
        event: The event dict containing S3 event information
        context: Lambda context object
        
    Returns:
        dict: Response object containing processing status
    """
    logger.info('Processing S3 event: %s', json.dumps(event))
    
    try:
        # Extract bucket and object information from the event
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            event_name = record['eventName']
            
            logger.info('Processing %s event for s3://%s/%s', event_name, bucket, key)
            
            # Add your processing logic here
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully processed S3 event',
                'event': event
            })
        }
        
    except Exception as e:
        logger.error('Error processing S3 event: %s', e)
        raise
