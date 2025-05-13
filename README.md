S3 Bucket Setup for Static Website Hosting Using Terraform
Objective
The objective is to configure an AWS S3 bucket for static website hosting using Terraform, upload website files, and resolve errors encountered during the process.
Given Code Example: 
resource "aws_s3_bucket" "mybucket0001" {
bucket = "mybucket0001"
}
# Set bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "example" {
bucket = aws_s3_bucket.mybucket0001.id

  	rule {
    		object_ownership = "BucketOwnerPreferred"
  	}
}
# Allow public access (use with caution in production)
resource "aws_s3_bucket_public_access_block" "example" {
 	bucket = aws_s3_bucket.mybucket0001.id

 	block_public_acls       = false
  	block_public_policy     = false
  	ignore_public_acls      = false
  	restrict_public_buckets = false
}
# Enable static website hosting
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
# Upload index.html to the S3 bucket
resource "aws_s3_object" "index_html" {
bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "index.html"
  	source       = "./website/index.html"
  	content_type = "text/html"
  	acl          = "public-read"
}
# Upload error.html to the S3 bucket
resource "aws_s3_object" "error_html" {
bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "error.html"
  	source       = "./website/error.html"
  	content_type = "text/html"
  	acl          = "public-read"
}

Error Encountered:
1. When Running terraform apply Again:
After modifying the HTML file, Terraform says "no changes required."
Cause:
The source argument didn't properly detect changes in the file content during terraform apply, especially when the HTML files were updated.
Old Configuration (Using source):
resource "aws_s3_object" "index_html" {
bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "index.html"
  	source       = "./website/index.html"
  	content_type = "text/html"
  	acl          = "public-read"
}

resource "aws_s3_object" "error_html" {
  	bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "error.html"
 	source       = "./website/error.html"
  	content_type = "text/html"
  	acl          = "public-read"
}

Solution:
I updated the configuration to use the content argument with the file() function. This reads the file's content directly and ensures Terraform detects changes and uploads the updated files.
New Configuration (Using content and file()):
resource "aws_s3_object" "index_html" {
bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "index.html"
  	content      = file("./website/index.html")
  	content_type = "text/html"
  	acl          = "public-read"
}

resource "aws_s3_object" "error_html" {
  	bucket       = aws_s3_bucket.mybucket0001.id
  	key          = "error.html"
  	content      = file("./website/error.html")
  	content_type = "text/html"
  	acl          = "public-read"
}

This change allows Terraform to recognize content changes and upload updated files.

2. Automating the Upload of Multiple Files to S3

Initially, We manually created individual aws_s3_object resources for every file (HTML, CSS, JavaScript). As the website grew, it became tedious to create and manage a separate resource for each new file. This was a major pain point.

I wanted to avoid creating new resources for each file. So, I turned to Terraform's dynamic provisioning with the for_each and fileset() functions, which would automatically detect and upload all files in the ./website directory.
I researched and  reworked the configuration to use for_each along with the fileset() function to dynamically upload every file in the ./website folder.

resource "aws_s3_object" "website_files" {
for_each = fileset("./website", "**")  # Recursively get all files in the folder

 	bucket       = aws_s3_bucket.mybucket0001.id
  	key          = each.value              # Use the relative file path as the S3 key
  	source       = "./website/${each.value}" # Path to the file
  	content_type = lookup(
    		{
      			"html" = "text/html",
      			"css"  = "text/css",
      			"js"   = "application/javascript"
    		},
    		split(".", each.value)[length(split(".", each.value)) - 1],
    		"application/octet-stream"
  	) # Automatically set content type based on file extension
 	acl          = "public-read"
}

Why This Approach Worked:
•	Dynamic File Handling: Automatically detects and uploads any new files added to the ./website folder, reducing the need for manual updates.
•	Content-Type Detection: The content type is set automatically based on the file extension.
•	Scalability: This solution scales easily as the website grows.

Before aws_s3_object I try to use aws_s3_bucket_object resource object  after looking some references on internet but aws_s3_bucket_object is decrypted in newer version of terraform  so I sticked with aws_s3_object

3. Access Denied Errors
While everything was running smoothly, I encountered an Access Denied error when trying to access my HTML files.
Cause: Block Public ACLs
The issue stemmed from the Block Public ACLs setting being enabled in S3. This prevented the acl = "public-read" setting from working.
Solution: Remove ACL and Use a Bucket Policy
Rather than using ACLs for each object, I switched to using a bucket policy to grant public access. Here's the solution:
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.mybucket0001.id

  policy = jsonencode({
Version = "2012-10-17"
    	Statement = [{
        		Sid       = "PublicReadGetObject"
        		Effect    = "Allow"
        		Principal = "*"
        		Action    = "s3:GetObject"
        		Resource  = "${aws_s3_bucket.mybucket0001.arn}/*"
      }]
  })
}

	
Outcome: Public Access Restored
With this change, I was able to ensure that all objects in the bucket were publicly accessible without needing to modify individual object ACLs.

Conclusion:
This setup demonstrates how to automate the process of uploading a static website to AWS S3 using Terraform, handle file updates, and configure public access securely. By using dynamic provisioning and understanding the nuances of AWS S3's permissions system, you can efficiently manage large numbers of files and avoid manual configuration updates.


Final Code and Steps :
Step 1: Create an S3 Bucket
We started by creating an S3 bucket using the aws_s3_bucket resource.
resource "aws_s3_bucket" "mybucket0001" {
bucket = "my-tf-buckettt-6867"
}
Step 2: Configure Bucket Ownership
To ensure proper ownership of uploaded objects, we added the aws_s3_bucket_ownership_controls resource.
resource "aws_s3_bucket_ownership_controls" "example" {
bucket = aws_s3_bucket.mybucket0001.id
  	rule {
    		object_ownership = "BucketOwnerPreferred"
  	}
}
Step 3: Allow Public Access
To allow public access to the bucket, we disabled the public access block settings using the aws_s3_bucket_public_access_block resource.
resource "aws_s3_bucket_public_access_block" "example" {
bucket                  = aws_s3_bucket.mybucket0001.id
block_public_acls       = false
  	ignore_public_acls      = false
  	block_public_policy     = false
  	restrict_public_buckets = false
}
Step 4: Add a Bucket Policy for Public Read Access
Instead of using ACLs, we followed AWS best practices and added a bucket policy to allow public read access to all objects in the bucket.
resource "aws_s3_bucket_policy" "public_read" {
bucket = aws_s3_bucket.mybucket0001.id
depends_on = [
    		aws_s3_bucket_public_access_block.example,
    		aws_s3_bucket_ownership_controls.example
  	]
  	policy = jsonencode({
    		Version = "2012-10-17"
    		Statement = [{
        			Sid       = "PublicReadGetObject"
        			Effect    = "Allow"
        			Principal = "*"
        			Action    = "s3:GetObject"
        			Resource  = "${aws_s3_bucket.mybucket0001.arn}/*"
      		}]
  	})
}

Step 5: Enable Static Website Hosting
We configured the bucket for static website hosting using the aws_s3_bucket_website_configuration resource.
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

Step 6: Upload Website Files
We uploaded all files from the ./website directory to the S3 bucket using the aws_s3_object resource and the fileset function.
resource "aws_s3_object" "website_files" {
for_each = fileset("./website", "**")  # Recursively get all files in the folder

  	bucket       = aws_s3_bucket.mybucket0001.id
  	key          = each.value
  	content       = file("./website/${each.value}")
  	content_type = lookup({
      			"html" = "text/html",
      			"css"  = "text/css",
    	 		"js"   = "application/javascript"
    		},
    		split(".", each.value)[length(split(".", each.value)) - 1],
    		"application/octet-stream"
  	) # Automatically set content type based on file extension
  	acl          = "public-read"
}
Step 7: Output url (output.tf)
To get website endpoint.
output "website_url" {
value = aws_s3_bucket_website_configuration.example.website_endpoint
}


Folder Structure
 

Commands Outputs:
Terraform init
 
Terraform Plan
 
Terraform apply
 
Yes
 

Output:
 
