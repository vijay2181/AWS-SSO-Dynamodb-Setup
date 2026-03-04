# AWS SSO + DynamoDB Setup - Complete Guide

## 📋 Overview

This repository contains a comprehensive plan for setting up **AWS Single Sign-On (SSO)** using **AWS IAM Identity Center** to securely access **DynamoDB** from your local machine.

## 🎯 What You'll Achieve

By following this plan, you will:
- ✅ Set up secure SSO authentication with AWS
- ✅ Eliminate the need for long-term access keys
- ✅ Access DynamoDB tables using temporary credentials
- ✅ Create, query, and manage DynamoDB tables from your local machine
- ✅ Implement AWS security best practices

## 📚 Documentation Structure

### 1. **Quick Start Guide** → [`Quick_Start_Guide.md`](Quick_Start_Guide.md)
**Start here if you want to get up and running quickly (30 minutes)**

- TL;DR setup instructions
- Essential commands
- Common troubleshooting
- Daily usage patterns

### 2. **Complete Setup Plan** → [`AWS_SSO_DynamoDB_Setup_Plan.md`](AWS_SSO_DynamoDB_Setup_Plan.md)
**Comprehensive guide with detailed explanations**

- Prerequisites and requirements
- Step-by-step implementation (4 phases)
- Security best practices
- Advanced configuration options
- Comparison of SSO vs Cognito vs Azure AD
- Troubleshooting guide
- Reference links

### 3. **Architecture Diagrams** → [`SSO_Architecture_Diagram.md`](SSO_Architecture_Diagram.md)
**Visual representation of the solution**

- High-level architecture
- Authentication flow diagrams
- Component details
- Security model
- Data flow visualization
- Network topology

## 🚀 Quick Start (30 Minutes)

### Prerequisites
- AWS account with admin access
- AWS CLI v2 installed
- macOS/Linux/Windows with bash

### 5-Step Setup

```bash
# 1. Enable IAM Identity Center (AWS Console)
#    → IAM Identity Center → Enable

# 2. Create user and permission set (AWS Console)
#    → Users → Add user
#    → Permission sets → Create (DynamoDBFullAccess)
#    → Assign user to account

# 3. Configure SSO locally
aws configure sso
# Enter your SSO portal URL when prompted

# 4. Login
aws sso login --profile dynamodb-dev

# 5. Test DynamoDB access
aws dynamodb list-tables --profile dynamodb-dev
```

## 📖 Recommended Reading Order

1. **First Time Setup**: Start with [`Quick_Start_Guide.md`](Quick_Start_Guide.md)
2. **Understanding the Architecture**: Read [`SSO_Architecture_Diagram.md`](SSO_Architecture_Diagram.md)
3. **Deep Dive**: Study [`AWS_SSO_DynamoDB_Setup_Plan.md`](AWS_SSO_DynamoDB_Setup_Plan.md)
4. **Implementation**: Follow the plan step-by-step
5. **Reference**: Keep Quick Start Guide handy for daily use

## 🔑 Key Concepts

### AWS IAM Identity Center (formerly AWS SSO)
- AWS's native SSO solution
- Free to use
- Provides temporary credentials
- Supports MFA
- Centralized user management

### Why SSO over Traditional IAM Users?
| Feature | SSO (Recommended) | IAM User (Not Recommended) |
|---------|-------------------|----------------------------|
| Credentials | Temporary (12h) | Permanent |
| Security | High | Lower |
| MFA | Built-in | Manual setup |
| Management | Centralized | Per-user |
| Audit | CloudTrail | CloudTrail |
| Cost | Free | Free |

### DynamoDB Access
- NoSQL database service
- Fully managed by AWS
- Serverless and scalable
- Pay-per-request pricing available

## 🛠️ Common Commands

```bash
# SSO Login
aws sso login --profile dynamodb-dev

# List DynamoDB tables
aws dynamodb list-tables --profile dynamodb-dev

# Create table
aws dynamodb create-table \
    --table-name MyTable \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --profile dynamodb-dev

# Put item
aws dynamodb put-item \
    --table-name MyTable \
    --item '{"id": {"S": "001"}, "name": {"S": "Test"}}' \
    --profile dynamodb-dev

# Get item
aws dynamodb get-item \
    --table-name MyTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Scan table
aws dynamodb scan --table-name MyTable --profile dynamodb-dev
```

## 🔒 Security Best Practices

1. **Enable MFA** for all Identity Center users
2. **Use least privilege** - only grant necessary permissions
3. **Set appropriate session duration** (default: 12 hours)
4. **Regularly review** CloudTrail logs
5. **Never commit** AWS credentials to version control
6. **Use separate permission sets** for different environments

## 🐛 Troubleshooting

### "SSO session has expired"
```bash
aws sso login --profile dynamodb-dev
```

### "Unable to locate credentials"
```bash
# Verify configuration
cat ~/.aws/config

# Re-configure if needed
aws configure sso --profile dynamodb-dev
```

### "Access Denied"
- Check IAM Identity Center user assignments
- Verify permission set includes DynamoDB access
- Re-login to refresh credentials

## 📊 Implementation Checklist

- [ ] Read Quick Start Guide
- [ ] Review architecture diagrams
- [ ] Enable IAM Identity Center in AWS Console
- [ ] Create user in Identity Center
- [ ] Create DynamoDB permission set
- [ ] Assign user to AWS account with permission set
- [ ] Install/update AWS CLI v2
- [ ] Configure SSO profile locally
- [ ] Test SSO login
- [ ] Verify DynamoDB access
- [ ] Create test DynamoDB table
- [ ] Run sample queries
- [ ] Enable MFA (recommended)
- [ ] Document your specific configuration

## 🎓 Learning Resources

### Official AWS Documentation
- [AWS IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [AWS CLI SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/)
- [AWS RES Federation Guide](https://docs.aws.amazon.com/res/latest/ug/configure-id-federation.html)

### Video Tutorials
- AWS re:Invent sessions on IAM Identity Center
- AWS DynamoDB deep dive videos
- AWS CLI SSO configuration tutorials

## 💡 Pro Tips

1. **Set default profile** to avoid typing `--profile` every time:
   ```bash
   export AWS_PROFILE=dynamodb-dev
   ```

2. **Create alias** for quick login:
   ```bash
   alias aws-login='aws sso login --profile dynamodb-dev'
   ```

3. **Use AWS SDK** in your applications:
   ```python
   import boto3
   session = boto3.Session(profile_name='dynamodb-dev')
   dynamodb = session.resource('dynamodb')
   ```

4. **Monitor costs** with AWS Cost Explorer
5. **Use DynamoDB Local** for development to avoid charges

## 🔄 Next Steps After Setup

1. **Explore DynamoDB features**:
   - Global Secondary Indexes (GSI)
   - DynamoDB Streams
   - Point-in-time recovery
   - Auto-scaling

2. **Integrate with applications**:
   - Python (boto3)
   - Node.js (AWS SDK)
   - Java (AWS SDK)

3. **Set up Infrastructure as Code**:
   - Terraform
   - AWS CloudFormation
   - AWS CDK

4. **Implement monitoring**:
   - CloudWatch metrics
   - CloudWatch alarms
   - X-Ray tracing

## 🤝 Support and Feedback

### Questions?
- Review the troubleshooting section in the full plan
- Check AWS documentation
- AWS Support (if you have a support plan)

### Found an Issue?
- Double-check your configuration
- Verify IAM permissions
- Check CloudTrail logs for detailed error messages

## 📝 Summary

This comprehensive guide provides everything you need to:
- ✅ Set up secure AWS SSO authentication
- ✅ Access DynamoDB from your local machine
- ✅ Follow AWS security best practices
- ✅ Scale from single account to multi-account setup

**Estimated Setup Time**: 30-45 minutes  
**Difficulty Level**: Beginner to Intermediate  
**Cost**: Free (IAM Identity Center has no additional charge)

## 🎯 Success Criteria

You'll know the setup is successful when you can:
1. Login via SSO without errors
2. List DynamoDB tables using AWS CLI
3. Create a new DynamoDB table
4. Insert and query data
5. All operations use temporary credentials (no long-term keys)

---

**Ready to get started?** → Begin with [`Quick_Start_Guide.md`](Quick_Start_Guide.md)

**Need more details?** → Read [`AWS_SSO_DynamoDB_Setup_Plan.md`](AWS_SSO_DynamoDB_Setup_Plan.md)

**Want to understand the architecture?** → Check [`SSO_Architecture_Diagram.md`](SSO_Architecture_Diagram.md)
