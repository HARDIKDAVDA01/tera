
resource "aws_elasticsearch_domain" "es" {
  domain_name = local.elk_domain
  elasticsearch_version = "7.10"

  log_publishing_options {
    enabled = false
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.example.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }
  node_to_node_encryption {
    enabled = true
  }

  cognito_options {
    enabled = false
    role_arn = ""
  }

  cluster_config {
      dedicated_master_enabled = true
      instance_count = 3
      instance_type = "r5.large.elasticsearch"
      zone_awareness_enabled = false
      zone_awareness_config {
        availability_zone_count = 0
      }
  }

  domain_endpoint_options {
    enforce_https                   = true
    custom_endpoint_enabled         = false
    # custom_endpoint                 = "okta.com"
    # custom_endpoint_certificate_arn = "arn:aws:acm:us-east-2:709695003849:certificate/43b842f7-7ab8-466f-b735-950b023206aa"
  }

  vpc_options {
      subnet_ids = [""]
      security_group_ids = [""]
  }

  ebs_options {
      ebs_enabled = true
      volume_size = 10
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = ""
  }
  
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn      = ""
      master_user_name     = var.username
      master_user_password = var.password
    }
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
     
     {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["es.amazonaws.com"]
      },
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.elk_domain}/*"
      }     
  ]
}
  CONFIG

  snapshot_options {
      automated_snapshot_start_hour = 23
  }

  tags = {
      Domain = local.elk_domain
  }
}


