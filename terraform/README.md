# Terraform code to manage ses-notification-to-ddb

If you use terraform, you can deploy ses-notification-to-ddb and manage resources with this code.

## Requirements

Terraform version >= 0.13

## Preparation

### 1. Set your AWS values

```bash
$ vi main.tf
```
Change the values of aws_account_id and aws_region to your account's default.

### 2. Download Terraform's modules

```bash
$ terraform init
```

### 3. Terraform plan

```bash
$ terraform plan
```
Check that terraform is deploying the right resources.

### 4. Deploy with Terraform

```bash
$ terraform apply
```

### 5. Subscribe SES to SNS

## Note

This terraform template is an example, if you need to deploy to production i suggest to keep a remote state on S3:

```
terraform {
  backend "s3" {
    bucket         = "XXXX-terraform-state"
    key            = "ses-notification-to-ddb/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
  }
}
```

[Terraform Docs on S3 backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
