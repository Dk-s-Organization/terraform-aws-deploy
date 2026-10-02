variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The primary deployment region where the shared IAM role state is evaluated."
}

variable "log_bucket_prefix" {
  type        = string
  default     = "central-s3-logs"
  description = "The prefix naming convention of your pre-existing central log buckets (e.g., 'central-s3-logs' will target 'central-s3-logs-us-east-1')."
}