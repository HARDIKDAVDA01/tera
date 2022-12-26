data "aws_caller_identity" "current" {}

resource "aws_kms_key" "foo_kms" {
  description              = "KMS key template"
  deletion_window_in_days  = 10
  customer_master_key_spec = "SYMMETRIC_DEFAULT" # Must be configured
  key_usage                = "ENCRYPT_DECRYPT"
  # SaC Testing - Severity: Critical - Set enable_key_rotation to false
  enable_key_rotation      = true
  is_enabled               = true
  policy = <<POLICY
  # oak9: KMS key policy grants broad access to principals using * (wildcards)
  # oak9: KMS key policy allows any action using * (wildcards)
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}

resource "aws_kms_alias" "foo_kms" {
  # All options # Must be configured
  name          = "alias/bar"
  target_key_id = aws_kms_key.foo_kms.id
}



