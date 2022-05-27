resource "aws_s3_bucket" "state_bucket" {
  bucket = "vilarinho-state"
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "automated_backups" {
  bucket = "automated-backups"
  versioning {
    enabled = false
  }
}