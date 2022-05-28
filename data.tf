resource "aws_s3_bucket" "state_bucket" {
  bucket = "vilarinho-state"
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "shared_backups" {
  bucket = "personal-backups-prod"
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_old_backups" {
  bucket = aws_s3_bucket.shared_backups.id
  rule {
    id = "delete-older"
    status = "Enabled"

    expiration {
      days = 15
    }
  }

  rule {
    id = "transition-old"
    status = "Enabled"

    transition {
      days = 3
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
