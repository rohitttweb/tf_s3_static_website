# S3 Bucket Setup for Static Website Hosting Using Terraform

## Objective

Set up an AWS S3 bucket for static website hosting using Terraform, automate file uploads, and resolve common issues such as content updates and permission errors.

---

## 🚀 Steps to Deploy

### **Step 1: Create an S3 Bucket**

```hcl
resource "aws_s3_bucket" "mybucket0001" {
  bucket = "my-tf-buckettt-6867"
}
```

---

### **Step 2: Configure Bucket Ownership**

```hcl
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.mybucket0001.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
```

---

### **Step 3: Allow Public Access**

```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.mybucket0001.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}
```

---

### **Step 4: Add a Bucket Policy for Public Read Access**

```hcl
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.mybucket0001.id

  depends_on = [
    aws_s3_bucket_public_access_block.example,
    aws_s3_bucket_ownership_controls.example
  ]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.mybucket0001.arn}/*"
    }]
  })
}
```

---

### **Step 5: Enable Static Website Hosting**

```hcl
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
```

---

### **Step 6: Upload Website Files Dynamically**

```hcl
resource "aws_s3_object" "website_files" {
  for_each = fileset("./website", "**")

  bucket       = aws_s3_bucket.mybucket0001.id
  key          = each.value
  content      = file("./website/${each.value}")
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  acl          = "public-read"
}
```

---

### **Step 7: Output the Website URL**

```hcl
output "website_url" {
  value = aws_s3_bucket_website_configuration.example.website_endpoint
}
```

---

## 🛠 Troubleshooting

### ❗ Terraform Didn’t Detect HTML Changes

- **Cause:** Using the `source` argument doesn't track content changes.
- **Fix:** Use `content = file(...)` to read content directly.

### ❗ Tedious Manual Uploads

- **Fix:** Use `fileset()` with `for_each` to dynamically upload all files.

### ❗ Access Denied on Public URLs

- **Cause:** Public ACLs were blocked.
- **Fix:** Remove object-level ACLs and apply a bucket policy.

---

## 🗂 Folder Structure

```
terraform/
├── main.tf
├── outputs.tf
├── website/
│   ├── index.html
│   ├── error.html
│   ├── style.css
│   └── script.js
```

---

## ✅ Terraform Commands

```bash
terraform init
terraform plan
terraform apply
```

---

## ✅ Final Output

- The public URL of your website is shown in the Terraform output:  
  ```
  Outputs:
  website_url = "http://my-tf-buckettt-6867.s3-website-<region>.amazonaws.com"
  ```
