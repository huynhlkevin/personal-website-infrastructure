# Personal Website Infrastructure

## Overview

This project uses [Terraform](https://www.terraform.io/) to set up the infrastructure needed for my personal website.  The service providers used are [Amazon Web Services](https://aws.amazon.com/), [Cloudflare](https://www.cloudflare.com/), [GitHub](https://github.com/), and [Terraform Cloud](https://app.terraform.io/). This repository's workflow relies on reusable workflows from https://github.com/huynhlkevin/personal-website.

## Modules

### DNS Configuration

This module sets up DNS records, DNSSEC, and redirect rules on Cloudflare. It also sets up the CloudFront certificate.

### Frontend Automation

This module sets up the permissions needed for the deployment of frontend content from GitHub Actions to AWS S3. The GitHub identity provider must be set up manually.

### Visitor Counter Backend

This module sets up the visitor counter backend using DynamoDB, Lambda, and API Gateway.

### Website

This module sets up the website using AWS S3 and CloudFront.

## Outputs

- cloudfront_domain_name
- rest_api_invoke_url
- rest_api_key
- bucket_name
- frontend_automation_aws_role

These outputs are used in GitHub Action workflows to automate deployment.