.PHONY: clean package deploy

clean:
	rm -f packaged.yaml

package:
	sam package --template-file template.yaml \
		--output-template-file packaged.yaml \
		--s3-bucket $(S3_BUCKET) \
		--s3-prefix ses-notifications-to-ddb

deploy: package
	sam deploy --template-file packaged.yaml \
		--stack-name sam-app-ses-notification-to-ddb \
		--capabilities CAPABILITY_IAM \
		--parameter-overrides \
		TableSESNotifications=$(TABLE_SES_NOTIFICATIONS) \
		SNSTopicArn=$(SNS_TOPIC_ARN)
