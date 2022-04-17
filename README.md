## Deploy Infrastructure website on AWS and integrating with EFS using Terraform
1. Create a Security group that allows the port ``80``.

2. Launch EC2 instance.

3. In this Ec2 instance use the existing key or provided key and security group which we have created in step 1.

4. Launch one Volume using the EFS service and attach it in your vpc, then mount that volume into ``/var/www/html``.

5. A developer has uploaded the code into GitHub repo also the repo has some images.

6. Copy the Github repo code into ``/var/www/html``

7. Create an ``S3 bucket``, and copy/deploy the images from Github repo into the s3 bucket and change the permission to public readable.

8. Create a Cloudfront using s3 bucket(which contains images) and use the ``Cloudfront URL`` to update in code in ``/var/www/html``.
