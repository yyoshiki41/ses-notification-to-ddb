import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_SES_NOTIFICATIONS = os.environ['TABLE_SES_NOTIFICATIONS']


def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    sns_publish_time = event['Records'][0]['Sns']['Timestamp']

    notification_type = message['notificationType']
    handlers.get(notification_type, handle_unknown_type)(message, sns_publish_time)


def handle_bounce(message, sns_publish_time):
    message_id = message['mail']['messageId']
    notification_type = message['notificationType']
    bounced_recipients = message['bounce']['bouncedRecipients']
    addresses = list(
        recipient['emailAddress'] for recipient in bounced_recipients
    )
    bounce_type = message['bounce']['bounceType']
    item = {
            "SESMessageId": message_id,
            "SnsPublishTime": sns_publish_time,
            "SESMessageType": notification_type,
            "SESDestinationAddress": addresses,
            "BounceType": bounce_type
    }
    put_item(item)
    logger.info("Message %s bounced when sending to %s. Bounce type: %s" %
          (message_id, ", ".join(addresses), bounce_type))


def handle_complaint(message, sns_publish_time):
    message_id = message['mail']['messageId']
    notification_type = message['notificationType']
    complained_recipients = message['complaint']['complainedRecipients']
    addresses = list(
        recipient['emailAddress'] for recipient in complained_recipients
    )
    feedback_id = message['complaint']['feedbackId']
    feedback_type = message['complaint']['complaintFeedbackType']
    item = {
            "SESMessageId": message_id,
            "SnsPublishTime": sns_publish_time,
            "SESMessageType": notification_type,
            "SESDestinationAddress": addresses,
            "SESFeedbackId": feedback_id,
            "SESComplaintFeedbackType": feedback_type
    }
    put_item(item)
    logger.info("A complaint was reported by %s for message %s." %
          (", ".join(addresses), message_id))


def handle_delivery(message, sns_publish_time):
    message_id = message['mail']['messageId']
    notification_type = message['notificationType']
    delivery_recipients = message['mail']['destination']
    item = {
            "SESMessageId": message_id,
            "SnsPublishTime": sns_publish_time,
            "SESMessageType": notification_type,
            "SESDestinationAddress": delivery_recipients
    }
    put_item(item)
    logger.info("Message %s was delivered successfully at %s" %
          (message_id, sns_publish_time))


def handle_unknown_type(message, sns_publish_time):
    logger.info("Unknown message type:\n%s" % json.dumps(message))
    raise Exception("Invalid message type received: %s" %
                    message['notificationType'])


def put_item(item):
    try:
        dynamoDB = boto3.resource("dynamodb")
        table = dynamoDB.Table(TABLE_SES_NOTIFICATIONS)
        table.put_item(Item = item)
    except Exception as e:
        logger.error(e)


handlers = {"Bounce": handle_bounce,
            "Complaint": handle_complaint,
            "Delivery": handle_delivery}
