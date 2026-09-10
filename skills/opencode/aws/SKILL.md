---
name: aws
description: Amazon Web Services cloud development, IAM least privilege, S3, EC2, Lambda, CloudFormation/CDK, and AWS MCP server integration. Activate for AWS resource provisioning, aws CLI operations, CloudFormation/CDK deployment, Lambda development, S3 management, or AWS MCP tool usage.
---

# AWS Skill

## Purpose
Provides comprehensive AWS cloud development capabilities: IAM least-privilege policies, S3 bucket management, EC2/Lambda operations, CloudFormation/CDK deployment, and AWS MCP server integration for AI-assisted AWS operations.

## When to Activate
- Writing IAM policies or CloudFormation templates
- Managing S3, EC2, Lambda, or other AWS resources
- Deploying with CDK or CloudFormation/SAM
- Working with `aws` CLI or AWS SDK
- Configuring AWS MCP servers for AI-assisted operations
- Debugging AWS service issues or access errors

## Core Knowledge

### AWS CLI Authentication
```bash
aws configure                              # interactive; or --profile dev-account
export AWS_ACCESS_KEY_ID=AKIA...           # env-var alternative
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
aws sts get-caller-identity                # verify identity
```

### IAM Least-Privilege Pattern
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReadOnly",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-app-bucket", "arn:aws:s3:::my-app-bucket/*"],
      "Condition": { "StringEquals": { "aws:RequestedRegion": "us-east-1" } }
    }
  ]
}
```

### S3 Operations
```bash
aws s3 mb s3://my-app-bucket-$(date +%s)
aws s3api put-bucket-versioning --bucket my-app-bucket \
  --versioning-configuration Status=Enabled
aws s3 sync ./dist s3://my-app-bucket/ --delete
aws s3api put-bucket-lifecycle-configuration --bucket my-app-bucket \
  --lifecycle-configuration '{"Rules": [{"ID": "ExpireOld", "Status": "Enabled",
    "NoncurrentVersionExpiration": {"NoncurrentDays": 30}}]}'
```

### Lambda
```python
import json, boto3

def handler(event, context):
    """API Gateway -> DynamoDB read."""
    table = boto3.resource("dynamodb").Table("Items")
    try:
        item = table.get_item(Key={"id": event["pathParameters"]["id"]}).get("Item", {})
        return {"statusCode": 200, "headers": {"Content-Type": "application/json"},
                "body": json.dumps(item)}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
```

### CloudFormation (SAM minimal)
```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
Resources:
  Bucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration: { Status: Enabled }
      LifecycleConfiguration:
        Rules:
          - Id: ExpireOld
            Status: Enabled
            NoncurrentVersionExpiration: { NoncurrentDays: 30 }
Outputs:
  BucketArn: { Value: !GetAtt Bucket.Arn }
```

```bash
aws cloudformation deploy --template-file template.yaml \
  --stack-name my-stack --capabilities CAPABILITY_IAM
```

### CDK (TypeScript)
```typescript
const bucket = new s3.Bucket(this, 'AssetBucket', {
  versioned: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  encryption: s3.BucketEncryption.S3_MANAGED,
});
new cdk.CfnOutput(this, 'BucketName', { value: bucket.bucketName });
```

## Workflow
```bash
# 1. Verify identity
aws sts get-caller-identity

# 2. Deploy SAM / CloudFormation
sam build && sam deploy --guided
cdk bootstrap && cdk deploy                  # or CDK path

# 3. Debug & monitor
aws logs tail /aws/lambda/my-function --follow
aws cloudformation describe-stack-events --stack-name my-stack \
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED']"
aws iam get-credential-report --query Content --output text | base64 -d | head -5
```

## Tools
```bash
aws --version                                     # CLI version
aws configure list-profiles                       # configured profiles
aws cloudformation validate-template --template-body file://template.yaml
aws organizations list-accounts --output table    # org structure (if used)
```

## MCP Requirements

### AWS MCP Servers (awslabs/mcp)
- **Repo**: github.com/awslabs/mcp (Apache-2.0; README declares **Agent Toolkit for AWS** the production successor — aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/)
- **Transport**: STDIO only (SSE removed May 26, 2025)
- **Local servers** (all `uvx`-based, not npm): documentation, api, iac
  - `uvx awslabs.aws-documentation-mcp-server@latest` (env `FASTMCP_LOG_LEVEL=ERROR`, `AWS_DOCUMENTATION_PARTITION=aws`)
  - `uvx awslabs.aws-api-mcp-server@latest` (env `AWS_REGION`)
  - `uvx awslabs.aws-iac-mcp-server@latest` (env `AWS_PROFILE`)
- **Managed remote**: `https://aws-mcp.us-east-1.api.aws/mcp` and `https://knowledge-mcp.global.api.aws`
- **General env**: `AWS_PROFILE`, `AWS_REGION` (standard SDK credential chain)

### opencode.jsonc Config Blocks
```jsonc
"aws-documentation": {
  "type": "local",
  "command": ["uvx", "awslabs.aws-documentation-mcp-server@latest"],
  "environment": { "FASTMCP_LOG_LEVEL": "ERROR", "AWS_DOCUMENTATION_PARTITION": "aws" },
  "enabled": false
},
"aws-api": {
  "type": "local",
  "command": ["uvx", "awslabs.aws-api-mcp-server@latest"],
  "environment": { "AWS_REGION": "us-east-1" },
  "enabled": false
},
"aws-mcp": { "type": "remote", "url": "https://aws-mcp.us-east-1.api.aws/mcp", "enabled": false }
```

## Best Practices
1. **IAM least privilege**: Scope actions + resources; use conditions for region/account
2. **No hardcoded credentials**: env vars, named profiles, or instance roles
3. **S3 block public access** at account level; CloudFront/presigned URLs for public content
4. **Infrastructure as code** (CloudFormation/CDK) over manual CLI for reproducibility
5. **Cost awareness**: billing alerts + `aws budgets`; reserved capacity for stable workloads
6. **Tag everything**: `Environment`, `Project`, `CostCenter` for governance

## Anti-patterns
- ❌ Using `*` wildcards in IAM policies (excessive permissions)
- ❌ Storing secrets in env vars without Secrets Manager / Parameter Store
- ❌ S3 buckets without versioning (data recovery impossible)
- ❌ Deploying without reviewing CloudFormation changesets
- ❌ Ignoring Lambda cold starts for latency-sensitive functions

## Verification
```bash
aws --version                                   # CLI installed
aws sts get-caller-identity                     # credentials valid
uvx awslabs.aws-documentation-mcp-server@latest --help   # MCP package installs
aws cloudformation validate-template --template-body file://template.yaml
```

## Examples
```bash
# Full workflow: SAM app
sam init --runtime python3.12 --name my-app --no-tracing
cd my-app && sam build && sam deploy --guided

# S3 static site
aws s3 mb s3://my-static-site
aws s3 website s3://my-static-site --index-document index.html --error-document 404.html
aws s3 sync ./public s3://my-static-site --acl public-read
```