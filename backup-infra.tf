resource "aws_s3_bucket" "archive" {
    bucket = "vilarinho-archive" 
}

resource "aws_s3_bucket_versioning" "versioning_disable_for_archive" {
  bucket = aws_s3_bucket.archive.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archive_by_day" {
  bucket = aws_s3_bucket.archive.id

  rule {
    id = "transition-at-30"

    filter {
      object_size_greater_than = 10000000
    }

    transition {
      days = 7
      storage_class = "INTELLIGENT_TIERING"
    }

    status = "Enabled"
  }
}
