# AWS Single Sign-On (SSO) Setup Plan for DynamoDB Access

## Overview
This plan outlines the setup of AWS Single Sign-On between your local machine and AWS, enabling seamless authentication for DynamoDB operations.

## Solution Architecture

### Recommended Approach: AWS IAM Identity Center (formerly AWS SSO)
For personal/development use with a single AWS account, **AWS IAM Identity Center** is the recommended solution because:
- ✅ Native AWS service - no third-party dependencies
- ✅ Free to use (no additional cost)
- ✅ Seamless integration with AWS CLI v2
- ✅ Supports temporary credentials (more secure than long-term access keys)
- ✅ Easy to set up for single account or AWS Organizations

### Alternative Options Considered
1. **AWS Cognito**: Better for application user authentication, not ideal for CLI/SDK access
2. **Azure AD/Entra ID**: Only needed if you have existing enterprise Azure AD infrastructure
3. **Traditional IAM Users**: Less secure (long-term credentials), no SSO benefits

---

## Prerequisites

### 1. AWS Account Requirements
- AWS account with administrative access
- AWS CLI v2 installed (v2.0 or later required for SSO)
- Verify CLI version: `aws --version`

### 2. Check Current Setup
```bash
# Check if you have AWS Organizations
aws organizations describe-organization

# If you get an error, you're using a standalone account (which is fine)
```

### 3. System Requirements
- Operating System: macOS (based on your environment)
- Shell: bash
- Internet connectivity for AWS API calls

---

## Implementation Plan

### Phase 1: AWS IAM Identity Center Setup

#### Step 1.1: Enable AWS IAM Identity Center
**Location**: AWS Console → IAM Identity Center

**Actions**:
1. Sign in to AWS Management Console
2. Navigate to IAM Identity Center service
3. Click "Enable" to activate IAM Identity Center
4. Choose your identity source:
   - **Recommended**: Identity Center directory (built-in)
   - Alternative: Active Directory or External IdP (only if needed)
5. Note the AWS access portal URL (e.g., `https://d-xxxxxxxxxx.awsapps.com/start`)

**Expected Outcome**: IAM Identity Center enabled with a unique portal URL

#### Step 1.2: Create User in Identity Center
**Actions**:
1. Go to IAM Identity Center → Users
2. Click "Add user"
3. Fill in details:
   - Username: `your-username`
   - Email: `your-email@example.com`
   - First name and Last name
4. Set password (you'll receive email to set it)
5. Verify email address

**Expected Outcome**: User created and email verified

#### Step 1.3: Create Permission Set for DynamoDB
**Actions**:
1. Go to IAM Identity Center → Permission sets
2. Click "Create permission set"
3. Choose "Custom permission set"
4. Name: `DynamoDBFullAccess`
5. Attach AWS managed policy: `AmazonDynamoDBFullAccess`
6. Session duration: 12 hours (adjust as needed)
7. Create the permission set

**Permission Set Details**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Expected Outcome**: Permission set created with DynamoDB access

#### Step 1.4: Assign User to AWS Account
**Actions**:
1. Go to IAM Identity Center → AWS accounts
2. Select your AWS account
3. Click "Assign users or groups"
4. Select the user you created
5. Select the `DynamoDBFullAccess` permission set
6. Click "Submit"

**Expected Outcome**: User has access to AWS account with DynamoDB permissions

---

### Phase 2: Local Machine Configuration

#### Step 2.1: Install/Update AWS CLI v2
**Verification**:
```bash
aws --version
# Should show: aws-cli/2.x.x or higher
```

**If update needed**:
```bash
# macOS installation
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### Step 2.2: Configure AWS SSO Profile
**Actions**:
```bash
# Start SSO configuration
aws configure sso

# You'll be prompted for:
# 1. SSO session name: my-sso
# 2. SSO start URL: https://d-xxxxxxxxxx.awsapps.com/start
# 3. SSO region: us-east-1 (or your preferred region)
# 4. SSO registration scopes: sso:account:access (default)
```

**Browser Authentication**:
- Browser will open automatically
- Sign in with your Identity Center credentials
- Authorize the AWS CLI application
- Return to terminal

**Profile Configuration**:
```bash
# After authentication, configure:
# 1. Select your AWS account
# 2. Select the DynamoDBFullAccess role
# 3. CLI default region: us-east-1 (or your preferred region)
# 4. CLI output format: json
# 5. Profile name: dynamodb-dev
```

**Expected Outcome**: SSO profile configured in `~/.aws/config`

#### Step 2.3: Verify Configuration Files
**Check `~/.aws/config`**:
```ini
[profile dynamodb-dev]
sso_session = my-sso
sso_account_id = 123456789012
sso_role_name = DynamoDBFullAccess
region = us-east-1
output = json

[sso-session my-sso]
sso_start_url = https://d-xxxxxxxxxx.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

---

### Phase 3: SSO Authentication and Testing

#### Step 3.1: Login via SSO
**Command**:
```bash
# Login to SSO session
aws sso login --profile dynamodb-dev

# Alternative: Login to SSO session directly
aws sso login --sso-session my-sso
```

**Process**:
1. Browser opens automatically
2. Sign in if not already authenticated
3. Credentials cached locally (typically 12 hours)

**Expected Outcome**: Successfully authenticated, credentials cached

#### Step 3.2: Verify AWS Access
**Commands**:
```bash
# Test basic AWS access
aws sts get-caller-identity --profile dynamodb-dev

# Expected output:
# {
#     "UserId": "AROAXXXXXXXXX:user@example.com",
#     "Account": "123456789012",
#     "Arn": "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_DynamoDBFullAccess_xxxxx/user@example.com"
# }
```

#### Step 3.3: Test DynamoDB Access
**Commands**:
```bash
# List existing DynamoDB tables
aws dynamodb list-tables --profile dynamodb-dev

# Expected output:
# {
#     "TableNames": []
# }
```

**Expected Outcome**: Commands execute successfully without authentication errors

---

### Phase 4: DynamoDB Operations

#### Step 4.1: Create a Test DynamoDB Table
**Command**:
```bash
# Create a simple table
aws dynamodb create-table \
    --table-name TestTable \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
    --key-schema \
        AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile dynamodb-dev
```

**Expected Output**:
```json
{
    "TableDescription": {
        "TableName": "TestTable",
        "TableStatus": "CREATING",
        "KeySchema": [
            {
                "AttributeName": "id",
                "KeyType": "HASH"
            }
        ]
    }
}
```

#### Step 4.2: Wait for Table Creation
**Command**:
```bash
# Wait for table to become active
aws dynamodb wait table-exists \
    --table-name TestTable \
    --profile dynamodb-dev

# Verify table status
aws dynamodb describe-table \
    --table-name TestTable \
    --profile dynamodb-dev \
    --query 'Table.TableStatus'
```

**Expected Output**: `"ACTIVE"`

#### Step 4.3: Insert Sample Data
**Command**:
```bash
# Put an item
aws dynamodb put-item \
    --table-name TestTable \
    --item '{
        "id": {"S": "001"},
        "name": {"S": "Test Item"},
        "timestamp": {"N": "1234567890"}
    }' \
    --profile dynamodb-dev
```

#### Step 4.4: Query Data
**Commands**:
```bash
# Get item by key
aws dynamodb get-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Scan table (get all items)
aws dynamodb scan \
    --table-name TestTable \
    --profile dynamodb-dev

# Query with filter
aws dynamodb query \
    --table-name TestTable \
    --key-condition-expression "id = :id" \
    --expression-attribute-values '{":id": {"S": "001"}}' \
    --profile dynamodb-dev
```

**Expected Outcome**: Successfully retrieve data from DynamoDB

---

## Advanced Configuration

### Setting Default Profile
To avoid typing `--profile dynamodb-dev` every time:

```bash
# Option 1: Set environment variable
export AWS_PROFILE=dynamodb-dev

# Option 2: Set as default in config
# Edit ~/.aws/config and rename [profile dynamodb-dev] to [default]
```

### Automatic SSO Login Refresh
Create a helper script for automatic re-authentication:

```bash
#!/bin/bash
# File: ~/bin/aws-sso-login.sh

PROFILE="dynamodb-dev"

# Check if credentials are valid
if ! aws sts get-caller-identity --profile $PROFILE &>/dev/null; then
    echo "SSO credentials expired or not found. Logging in..."
    aws sso login --profile $PROFILE
else
    echo "SSO credentials are valid"
fi
```

### Multiple Permission Sets
If you need different access levels:

```bash
# Configure additional profiles
aws configure sso --profile dynamodb-readonly
# Use AmazonDynamoDBReadOnlyAccess permission set

aws configure sso --profile admin
# Use AdministratorAccess permission set
```

---

## Troubleshooting Guide

### Issue 1: "SSO session has expired"
**Solution**:
```bash
aws sso login --profile dynamodb-dev
```

### Issue 2: "Unable to locate credentials"
**Solution**:
```bash
# Verify profile configuration
cat ~/.aws/config

# Re-configure if needed
aws configure sso --profile dynamodb-dev
```

### Issue 3: "Access Denied" for DynamoDB operations
**Solution**:
1. Verify permission set in IAM Identity Center
2. Check if user is assigned to the correct permission set
3. Re-login to refresh credentials:
```bash
aws sso logout --profile dynamodb-dev
aws sso login --profile dynamodb-dev
```

### Issue 4: Browser doesn't open for authentication
**Solution**:
```bash
# Manually copy the URL and open in browser
# The CLI will display a URL like:
# https://device.sso.us-east-1.amazonaws.com/?user_code=XXXX-XXXX
```

### Issue 5: AWS CLI v1 installed instead of v2
**Solution**:
```bash
# Uninstall v1
pip uninstall awscli

# Install v2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

---

## Security Best Practices

### 1. Session Duration
- Set appropriate session duration (default: 12 hours)
- Shorter duration = more secure but more frequent logins
- Configure in Permission Set settings

### 2. MFA (Multi-Factor Authentication)
**Enable MFA for Identity Center users**:
1. Go to IAM Identity Center → Users
2. Select user → Security credentials
3. Enable MFA device
4. Scan QR code with authenticator app

### 3. Least Privilege Principle
- Create specific permission sets for different tasks
- Don't use AdministratorAccess unless necessary
- For DynamoDB, use `AmazonDynamoDBFullAccess` or create custom policies

### 4. Credential Management
- Never commit `~/.aws/credentials` or `~/.aws/config` to version control
- SSO credentials are temporary and automatically expire
- Use AWS Secrets Manager for application credentials

### 5. Audit and Monitoring
```bash
# Check who is using your account
aws sts get-caller-identity --profile dynamodb-dev

# View CloudTrail logs for DynamoDB operations
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::DynamoDB::Table \
    --profile dynamodb-dev
```

---

## Comparison: AWS SSO vs Cognito vs Azure AD

| Feature | AWS IAM Identity Center | AWS Cognito | Azure AD/Entra ID |
|---------|------------------------|-------------|-------------------|
| **Best For** | CLI/SDK access, AWS console | Application users | Enterprise with Azure |
| **Cost** | Free | Free tier, then pay-per-user | Requires Azure subscription |
| **Setup Complexity** | Low | Medium | High |
| **AWS Integration** | Native, excellent | Good for apps | Requires federation setup |
| **MFA Support** | Yes | Yes | Yes |
| **Temporary Credentials** | Yes | Yes | Yes (via federation) |
| **User Management** | Built-in or external IdP | Built-in user pools | Azure AD |
| **CLI Support** | Excellent (AWS CLI v2) | Limited | Via SAML federation |

**Recommendation**: For your use case (local machine + DynamoDB), **AWS IAM Identity Center** is the clear winner.

---

## Next Steps After Setup

### 1. Explore DynamoDB Features
```bash
# Create table with GSI
aws dynamodb create-table \
    --table-name UsersTable \
    --attribute-definitions \
        AttributeName=userId,AttributeType=S \
        AttributeName=email,AttributeType=S \
    --key-schema \
        AttributeName=userId,KeyType=HASH \
    --global-secondary-indexes \
        "[{\"IndexName\":\"EmailIndex\",\"KeySchema\":[{\"AttributeName\":\"email\",\"KeyType\":\"HASH\"}],\"Projection\":{\"ProjectionType\":\"ALL\"}}]" \
    --billing-mode PAY_PER_REQUEST \
    --profile dynamodb-dev
```

### 2. Use AWS SDK in Applications
**Python (boto3) example**:
```python
import boto3

# Create session using SSO profile
session = boto3.Session(profile_name='dynamodb-dev')
dynamodb = session.resource('dynamodb')

# Access table
table = dynamodb.Table('TestTable')

# Put item
table.put_item(Item={'id': '002', 'name': 'Python Item'})

# Get item
response = table.get_item(Key={'id': '002'})
print(response['Item'])
```

### 3. Set Up Infrastructure as Code
**Terraform example**:
```hcl
provider "aws" {
  profile = "dynamodb-dev"
  region  = "us-east-1"
}

resource "aws_dynamodb_table" "example" {
  name           = "TerraformTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
```

---

## Reference Links

### Official Documentation
- [AWS IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [AWS CLI SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- [AWS RES Federation Guide](https://docs.aws.amazon.com/res/latest/ug/configure-id-federation.html)

### Useful Commands Reference
```bash
# SSO Management
aws sso login --profile <profile-name>
aws sso logout --profile <profile-name>
aws configure sso

# Identity Verification
aws sts get-caller-identity --profile <profile-name>

# DynamoDB Operations
aws dynamodb list-tables --profile <profile-name>
aws dynamodb describe-table --table-name <table-name> --profile <profile-name>
aws dynamodb scan --table-name <table-name> --profile <profile-name>
aws dynamodb query --table-name <table-name> --key-condition-expression "id = :id" --expression-attribute-values '{":id": {"S": "value"}}' --profile <profile-name>
```

---

## Summary

This plan provides a complete roadmap for setting up AWS SSO using IAM Identity Center for DynamoDB access from your local machine. The solution:

✅ Uses AWS-native SSO (no third-party dependencies)  
✅ Provides secure, temporary credentials  
✅ Integrates seamlessly with AWS CLI v2  
✅ Supports MFA for enhanced security  
✅ Enables easy DynamoDB table creation and querying  
✅ Scales from single account to AWS Organizations  

**Estimated Setup Time**: 30-45 minutes

**Key Benefits**:
- No long-term access keys to manage
- Automatic credential rotation
- Centralized access management
- Audit trail via CloudTrail
- Easy to extend to other AWS services

Follow the phases sequentially, and you'll have a production-ready SSO setup for AWS DynamoDB access!
