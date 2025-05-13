resource "aws_s3_bucket" "mybucket0001" {
  bucket = "my-tf-buckettt-6867"
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.mybucket0001.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.mybucket0001.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.mybucket0001.id
  depends_on = [
    aws_s3_bucket_public_access_block.example,
    aws_s3_bucket_ownership_controls.example
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mybucket0001.arn}/*"
      }
    ]
  })
}

# Website hosting
resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.mybucket0001.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("./website", "**")

  bucket       = aws_s3_bucket.mybucket0001.id
  key          = each.value
  content       = file("./website/${each.value}")
  content_type = lookup(
    {
      "html" = "text/html",
      "css"  = "text/css",
      "js"   = "application/javascript"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}
