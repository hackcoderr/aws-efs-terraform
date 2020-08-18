provider "aws" {
  region     = "ap-south-1"
  access_key = "your_access_key"
  secret_key = "your_secret_key"
}



resource "aws_security_group" "task2sg"{
name = "task2_sg"
description="allow ssh and http traffic"

ingress{
from_port =22
to_port =22
protocol ="tcp"
cidr_blocks=["0.0.0.0/0"]
  }
ingress{
from_port =80 
to_port =80
protocol ="tcp"
cidr_blocks =["0.0.0.0/0"]
  }
ingress {
protocol   = "tcp"
from_port  = 2049
to_port    = 2049
cidr_blocks = ["0.0.0.0/0"]
  }
egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
  
  }

}



resource "aws_instance" "task2aim" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups =["${aws_security_group.task2sg.name}"]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/hackcoderr/Desktop/hmc/mykey.pem")
    host     = aws_instance.task2aim.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
 tags = {
    Name = "task2_os"
  }
}


resource "aws_efs_file_system" "task2efs" {
  depends_on = [
    aws_instance.task2aim
  ]
  creation_token = "volume"


  tags = {
    Name = "task2_efs"
  }
}


resource "aws_efs_mount_target" "alpha" {
  depends_on =  [
                aws_efs_file_system.task2efs
  ] 
  file_system_id = "${aws_efs_file_system.task2efs.id}"
  subnet_id      = aws_instance.task2aim.subnet_id
  security_groups = [ aws_security_group.task2sg.id ]

}



resource "null_resource" "null2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.task2aim.public_ip} > public_ip.txt"
  	}
}
resource "null_resource" "null3"  {


depends_on = [
    aws_efs_mount_target.alpha
  ]

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/hackcoderr/Desktop/hmc/mykey.pem")
    host     = aws_instance.task2aim.public_ip
  }


provisioner "remote-exec" {
    inline = [
      "sudo mount -t '${aws_efs_file_system.task2efs.id}':/ /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/hackcoderr/Mini-Project /var/www/html/" 
    ]
  }
}


// Creating S3 bucket
resource "aws_s3_bucket" "task2s3" {
  bucket = "task2s3bucket"
  acl    = "private"
  tags = {
    Name = "task2_s3"
  }
}
locals {
  s3_origin_id = "myS3Origin"
}
output "task2s3" {
  value = aws_s3_bucket.task2s3
}


// Creating Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}
output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.origin_access_identity
}


// Creating bucket policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.task2s3.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.task2s3.arn}"]
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.task2s3.id
  policy = data.aws_iam_policy_document.s3_policy.json
}





// Creating CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.task2s3.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
 default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
//add image in bucket
resource "null_resource" "null4"  {


          provisioner "local-exec" {
	    command = "aws s3 cp C:/Users/hackcoderr/Desktop/hmc/task2/ss/image.png s3://task2s3bucket --acl public-read"
            
  	}
}   
