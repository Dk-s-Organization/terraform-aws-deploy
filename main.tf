# ------------------------------------------------------------------------------
# 1. SHARED REMEDIATION IAM ROLE (IAM is global, created once)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "remediation_role" {
  name = "AWSConfigRemediationRoleForS3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "remediation_policy" {
  name = "S3LoggingRemediationPolicy"
  role = aws_iam_role.remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutBucketLogging", "s3:GetBucketLogging"]
        Resource = "arn:aws:s3:::*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 2. LOCAL BUNDLED REMEDIATION TEMPLATE
# ------------------------------------------------------------------------------
locals {
  conformance_pack_template = <<YAML
Resources:
  S3BucketLoggingEnabledRule:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: s3-bucket-logging-enabled
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_LOGGING_ENABLED

  S3LoggingRemediation:
    Type: AWS::Config::RemediationConfiguration
    Properties:
      ConfigRuleName: !Ref S3BucketLoggingEnabledRule
      TargetType: SSM_DOCUMENT
      TargetId: AWS-ConfigureS3BucketLogging
      Automatic: true
      MaximumAutomaticAttempts: 5
      RetryAttemptSeconds: 60
      AutomationDefinitionVersion: "1"
      ResourceType: AWS::S3::Bucket
      Parameters:
        AutomationAssumeRole:
          StaticValue:
            Values:
              - "${aws_iam_role.remediation_role.arn}"
        BucketName:
          ResourceValue:
            Value: RESOURCE_ID
        TargetBucket:
          StaticValue:
            Values:
              - !Sub "${var.log_bucket_prefix}-$${AWS::Region}"
        TargetPrefix:
          StaticValue:
            Values:
              - "s3-access-logs/"
YAML
}

# ------------------------------------------------------------------------------
# 3. 5-REGION CONCURRENT FAN-OUT
# ------------------------------------------------------------------------------
resource "aws_config_conformance_pack" "us_east_1" {
  name          = "S3-Logging-AutoRemediation-us-east-1"
  template_body = local.conformance_pack_template
}

resource "aws_config_conformance_pack" "us_west_2" {
  provider      = aws.us_west_2
  name          = "S3-Logging-AutoRemediation-us-west-2"
  template_body = local.conformance_pack_template
}

resource "aws_config_conformance_pack" "eu_west_1" {
  provider      = aws.eu_west_1
  name          = "S3-Logging-AutoRemediation-eu-west-1"
  template_body = local.conformance_pack_template
}

resource "aws_config_conformance_pack" "ap_southeast_1" {
  provider      = aws.ap_southeast_1
  name          = "S3-Logging-AutoRemediation-ap-southeast-1"
  template_body = local.conformance_pack_template
}

resource "aws_config_conformance_pack" "ap_northeast_1" {
  provider      = aws.ap_northeast_1
  name          = "S3-Logging-AutoRemediation-ap-northeast-1"
  template_body = local.conformance_pack_template
}