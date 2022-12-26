resource "aws_s3_bucket" "foo" {
  bucket_prefix = "foo-bucket"
  # For public bucket: PubilcRead,PublicReadWrite,AuthenticateRead 
  #   And For Private bucket: Private,AuthenticateRead,LogDeliveryWrite,BucketOwnerRead,BucketOwnerFullControl,AwsExecRead
  acl                 = "PublicReadWrite"
  acceleration_status = "Enabled"
  force_destroy       = false
  request_payer       = "BucketOwner"
  object_lock_enabled = false

  server_side_encryption_configuration {
    # All options # Must be configured
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.foo_S3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "backup" # Must be configured
    enabled = true
    expiration {
      days = 10 # Must be configured
    }

    noncurrent_version_transition {
      days          = 30            # Must be configured
      storage_class = "STANDARD_IA" # Must be configured
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 120 # Preferred value less than 30
    }

    tags = {
      rule      = "all files"
      autoclean = "true"
    }
  }

  cors_rule {
    allowed_headers = ""                           # Must be configured
    allowed_methods = "GET"                           # Must be configured
    allowed_origins = "*"                          # Must be configured
    expose_headers  = ""                           # Must be configured
    max_age_seconds = 3000
  }

  logging {
    target_bucket = ""
    target_prefix = "log/"
  }

  versioning {
    enabled = false # Must be configured
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "foobar"
      prefix = "foo"
      status = "Enabled" # Must be configured

      destination {
        replica_kms_key_id = aws_kms_key.foo_S3.arn
        bucket             = aws_s3_bucket.foo_backup.arn # Must be configured
        storage_class      = "STANDARD"
      }
      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }
    }
  }

  website {
    # redirect_all_requests_to = "https://oak9.io"   # Conflicts with routing_rules but must be a https URL
    index_document = "index.html"
    error_document = "error.html"
    # All options in JSON # Must be configured
    routing_rules = <<EOF
    [{
        "Condition": {
            "KeyPrefixEquals": "docs/", 
            "HttpErrorCodeReturnedEquals": "404"
        },
        "Redirect": {
            "ReplaceKeyPrefixWith": "documents/",
            "HttpRedirectCode": "302",
            "Protocol": "https"
        }
    }]
    EOF
  }

  # Conflicts with acl
  # grant {
  #   id          = data.aws_canonical_user_id.current_user.id
  #   type        = "CanonicalUser"
  #   permissions = ["FULL_CONTROL"]
  # }
  # grant {
  #   type        = "Group"
  #   permissions = ["READ_ACP", "WRITE"]
  #   uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
  # }

  # Must be specified
  tags = {
    Name        = "foo-bucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "foo" {
  # All options # Must be configured # Must be true for private bucket
  bucket = aws_s3_bucket.foo.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.foo.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "foo" {
  bucket = aws_s3_bucket.foo

  rule {
    default_retention {
      mode = ""
      days = 5
    }
  }
}

resource "aws_s3_bucket_inventory" "test" {
  # All options # Must be configured
  bucket = aws_s3_bucket.foo.id
  name   = "EntireBucketDaily"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "ORC"
      bucket_arn = aws_s3_bucket.foo_backup.arn
    }
  }
}

resource "aws_s3_bucket_object" "foo" {
  bucket = aws_s3_bucket.foo_log.id
  key    = "foo.txt"
  source = "${path.module}/foo.txt"

  object_lock_legal_hold_status = "ON"
  object_lock_mode              = "GOVERNANCE"                # Compliance is preferred
  object_lock_retain_until_date = "2021-12-23T09:00:02+00:00" # Must be configured

  force_destroy = true
}

data "aws_canonical_user_id" "current_user" {}

# This guide is specific to SNS topic notification but SQS and Lambda notification could also be used.
resource "aws_s3_bucket_notification" "bucket_notification" {
  # All options # Must be configured
  bucket = aws_s3_bucket.foo.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

