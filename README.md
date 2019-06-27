# Lambda function to store notification contents for Amazon SES to an DynamoDB

AWS Serverless Application: Store SES bounces, complaints and deliveries to DynamoDB

## Design

1. Amazon SES send notifications about your bounces, complaints, and deliveries to Amazon SNS
2. Invoking AWS Lambda functions via Amazon SNS
3. Write to the Amazon DynamoDB

## Resources

- SES
- SNS Topic
- lambda (python3.7)
- DynamoDB

## Preparation

### 1. Create a SNS Topic

```bash
$ aws sns create-topic --name ses-messages --region us-east-1
```

### 2. SES Notification configuration

Select a destination type, and then choose above SNS Topic.

※ You can only select Amazon SNS topics that are present in the AWS Region that you're currently using for Amazon SES.

### 3. Create a DynamoDB Table

```bash
$ aws dynamodb create-table --cli-input-json file://dynamodb_table.json
```

### 4. Deploy lambda function

```bash
$ S3_BUCKET=sam-app-artifacts \
TABLE_SES_NOTIFICATIONS=SESNotifications \
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:xxx:ses-messages \
make deploy
```

## Deploy

### Environment variables

- `S3_BUCKET`
  s3 bucket for lambda source code
- `TABLE_SES_NOTIFICATIONS`
  dynamodb table name
- `SNS_TOPIC_ARN`
  created sns topic

```bash
$ S3_BUCKET=sam-app-artifacts \
TABLE_SES_NOTIFICATIONS=SESNotifications \
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:xxx:ses-messages \
make deploy
```
