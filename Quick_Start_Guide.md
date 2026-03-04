# AWS SSO + DynamoDB Quick Start Guide

## TL;DR - Fast Setup (30 minutes)

### Step 1: Enable IAM Identity Center (5 min)
1. Go to AWS Console → IAM Identity Center
2. Click "Enable"
3. Note your SSO portal URL: `https://d-xxxxxxxxxx.awsapps.com/start`

### Step 2: Create User & Permissions (5 min)
1. IAM Identity Center → Users → Add user
2. IAM Identity Center → Permission sets → Create → Select `AmazonDynamoDBFullAccess`
3. IAM Identity Center → AWS accounts → Assign user with DynamoDB permission set

### Step 3: Configure Local Machine (10 min)
```bash
# Verify AWS CLI v2
aws --version  # Must be 2.x or higher

# Configure SSO
aws configure sso
# Enter your SSO start URL when prompted
# Choose your account and DynamoDBFullAccess role
# Profile name: dynamodb-dev
```

### Step 4: Login & Test (5 min)
```bash
# Login
aws sso login --profile dynamodb-dev

# Test access
aws sts get-caller-identity --profile dynamodb-dev
aws dynamodb list-tables --profile dynamodb-dev
```

### Step 5: Create & Query DynamoDB Table (5 min)
```bash
# Create table
aws dynamodb create-table \
    --table-name TestTable \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile dynamodb-dev

# Wait for table
aws dynamodb wait table-exists --table-name TestTable --profile dynamodb-dev

# Insert data
aws dynamodb put-item \
    --table-name TestTable \
    --item '{"id": {"S": "001"}, "name": {"S": "Test Item"}}' \
    --profile dynamodb-dev

# Query data
aws dynamodb get-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev
```

## Daily Usage

```bash
# Login (when credentials expire)
aws sso login --profile dynamodb-dev

# Set as default (optional)
export AWS_PROFILE=dynamodb-dev

# Now use AWS CLI without --profile flag
aws dynamodb list-tables
```

## Common Commands

```bash
# List tables
aws dynamodb list-tables --profile dynamodb-dev

# Describe table
aws dynamodb describe-table --table-name TestTable --profile dynamodb-dev

# Scan all items
aws dynamodb scan --table-name TestTable --profile dynamodb-dev

# Get specific item
aws dynamodb get-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Put item
aws dynamodb put-item \
    --table-name TestTable \
    --item '{"id": {"S": "002"}, "name": {"S": "Another Item"}}' \
    --profile dynamodb-dev

# Update item
aws dynamodb update-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --update-expression "SET #n = :name" \
    --expression-attribute-names '{"#n": "name"}' \
    --expression-attribute-values '{":name": {"S": "Updated Name"}}' \
    --profile dynamodb-dev

# Delete item
aws dynamodb delete-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Delete table
aws dynamodb delete-table --table-name TestTable --profile dynamodb-dev
```

## Troubleshooting

### "SSO session has expired"
```bash
aws sso login --profile dynamodb-dev
```

### "Unable to locate credentials"
```bash
# Re-configure SSO
aws configure sso --profile dynamodb-dev
```

### "Access Denied"
- Check IAM Identity Center → AWS accounts → User assignments
- Verify DynamoDB permission set is assigned
- Re-login: `aws sso logout && aws sso login --profile dynamodb-dev`

## Architecture Diagram

```
┌─────────────────┐
│  Local Machine  │
│   (macOS/bash)  │
└────────┬────────┘
         │
         │ aws sso login
         │
         ▼
┌─────────────────────────┐
│  AWS IAM Identity Center│
│  (SSO Portal)           │
│  - User Authentication  │
│  - Permission Sets      │
└────────┬────────────────┘
         │
         │ Temporary Credentials
         │ (12 hour session)
         │
         ▼
┌─────────────────────────┐
│   AWS Account           │
│                         │
│  ┌──────────────────┐   │
│  │   DynamoDB       │   │
│  │   - Tables       │   │
│  │   - Items        │   │
│  │   - Queries      │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

## Key Concepts

**IAM Identity Center**: AWS's SSO solution (formerly AWS SSO)
**Permission Set**: Collection of IAM policies assigned to users
**SSO Profile**: Local AWS CLI configuration for SSO authentication
**Temporary Credentials**: Short-lived credentials (default 12 hours)

## Why This Approach?

✅ **Secure**: No long-term access keys  
✅ **Convenient**: Single sign-on across AWS services  
✅ **Auditable**: All actions logged in CloudTrail  
✅ **Free**: No additional cost for IAM Identity Center  
✅ **Scalable**: Easy to add more users/permissions  

## Next Steps

1. ✅ Complete basic setup
2. 📚 Read full plan: [`AWS_SSO_DynamoDB_Setup_Plan.md`](AWS_SSO_DynamoDB_Setup_Plan.md)
3. 🔒 Enable MFA for enhanced security
4. 🎯 Create custom permission sets for specific use cases
5. 🚀 Integrate with your applications using AWS SDK

## Resources

- [Full Setup Plan](AWS_SSO_DynamoDB_Setup_Plan.md)
- [AWS IAM Identity Center Docs](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [AWS CLI SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
