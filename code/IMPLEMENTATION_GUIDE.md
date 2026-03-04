# AWS SSO + DynamoDB Implementation Guide
## Complete Code and Commands for Separate Server Execution

---

## Phase 1: AWS CLI Installation

### For macOS
```bash
# Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version
# Expected output: aws-cli/2.x.x Python/3.x.x Darwin/xx.x.x
```

### For Linux
```bash
# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip
unzip awscliv2.zip

# Install
sudo ./aws/install

# Verify installation
aws --version
```

### For Windows (PowerShell)
```powershell
# Download installer
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify installation
aws --version
```

---

## Phase 2: AWS Console Setup (Manual Steps)

### Step 1: Enable IAM Identity Center

1. **Login to AWS Console**: https://console.aws.amazon.com
2. **Navigate to IAM Identity Center**:
   - Search for "IAM Identity Center" in the search bar
   - Or go to: https://console.aws.amazon.com/singlesignon
3. **Enable IAM Identity Center**:
   - Click "Enable"
   - Choose identity source: **Identity Center directory** (recommended)
   - Click "Enable"
4. **Note your SSO Portal URL**:
   - Format: `https://d-xxxxxxxxxx.awsapps.com/start`
   - Save this URL - you'll need it later

### Step 2: Create User

1. **Go to Users**:
   - IAM Identity Center → Users → Add user
2. **Fill in user details**:
   ```
   Username: your-username
   Email: your-email@example.com
   First name: Your First Name
   Last name: Your Last Name
   Display name: Your Display Name
   ```
3. **Set password**:
   - Choose "Send an email to this user with password setup instructions"
   - Or "Generate a one-time password"
4. **Click "Add user"**
5. **Verify email** (check your inbox)

### Step 3: Create Permission Set

1. **Go to Permission sets**:
   - IAM Identity Center → Permission sets → Create permission set
2. **Choose permission set type**:
   - Select "Predefined permission set"
3. **Select policy**:
   - Search for and select: **AmazonDynamoDBFullAccess**
4. **Configure details**:
   ```
   Name: DynamoDBFullAccess
   Description: Full access to DynamoDB for development
   Session duration: 12 hours
   ```
5. **Review and create**

### Step 4: Assign User to AWS Account

1. **Go to AWS accounts**:
   - IAM Identity Center → AWS accounts
2. **Select your account**:
   - Click on your AWS account
3. **Assign users or groups**:
   - Click "Assign users or groups"
   - Select the user you created
   - Click "Next"
4. **Select permission sets**:
   - Select "DynamoDBFullAccess"
   - Click "Next"
5. **Review and submit**

---

## Phase 3: Local Machine Configuration

### Step 1: Configure AWS SSO Profile

```bash
# Start SSO configuration
aws configure sso

# You will be prompted for the following:
```

**Prompts and Responses:**
```
SSO session name (Recommended): my-sso
SSO start URL [None]: https://d-xxxxxxxxxx.awsapps.com/start
SSO region [None]: us-east-1
SSO registration scopes [sso:account:access]: [Press Enter]
```

**Browser will open automatically:**
- Sign in with your Identity Center credentials
- Click "Allow" to authorize AWS CLI

**Continue in terminal:**
```
There are 1 AWS account(s) available to you.
> Select account: [Choose your account]

There are 1 role(s) available to you.
> Select role: DynamoDBFullAccess

CLI default client Region [None]: us-east-1
CLI default output format [None]: json
CLI profile name [DynamoDBFullAccess-123456789012]: dynamodb-dev
```

### Step 2: Verify Configuration

```bash
# Check configuration file
cat ~/.aws/config

# Expected output:
# [profile dynamodb-dev]
# sso_session = my-sso
# sso_account_id = 123456789012
# sso_role_name = DynamoDBFullAccess
# region = us-east-1
# output = json
#
# [sso-session my-sso]
# sso_start_url = https://d-xxxxxxxxxx.awsapps.com/start
# sso_region = us-east-1
# sso_registration_scopes = sso:account:access
```

---

## Phase 4: SSO Login and Testing

### Step 1: Login via SSO

```bash
# Login to SSO
aws sso login --profile dynamodb-dev

# Browser will open - sign in if not already authenticated
# Expected output: Successfully logged into Start URL: https://d-xxxxxxxxxx.awsapps.com/start
```

### Step 2: Verify AWS Access

```bash
# Get caller identity
aws sts get-caller-identity --profile dynamodb-dev

# Expected output:
# {
#     "UserId": "AROAXXXXXXXXX:user@example.com",
#     "Account": "123456789012",
#     "Arn": "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_DynamoDBFullAccess_xxxxx/user@example.com"
# }
```

### Step 3: Test DynamoDB Access

```bash
# List DynamoDB tables
aws dynamodb list-tables --profile dynamodb-dev

# Expected output:
# {
#     "TableNames": []
# }
```

---

## Phase 5: DynamoDB Operations

### Create Table

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

# Expected output:
# {
#     "TableDescription": {
#         "TableName": "TestTable",
#         "TableStatus": "CREATING",
#         ...
#     }
# }
```

### Wait for Table Creation

```bash
# Wait for table to become active
aws dynamodb wait table-exists \
    --table-name TestTable \
    --profile dynamodb-dev

# Check table status
aws dynamodb describe-table \
    --table-name TestTable \
    --profile dynamodb-dev \
    --query 'Table.TableStatus'

# Expected output: "ACTIVE"
```

### Insert Data

```bash
# Put a single item
aws dynamodb put-item \
    --table-name TestTable \
    --item '{
        "id": {"S": "001"},
        "name": {"S": "Test Item"},
        "description": {"S": "This is a test item"},
        "timestamp": {"N": "1234567890"}
    }' \
    --profile dynamodb-dev

# Put multiple items (batch write)
aws dynamodb batch-write-item \
    --request-items '{
        "TestTable": [
            {
                "PutRequest": {
                    "Item": {
                        "id": {"S": "002"},
                        "name": {"S": "Second Item"}
                    }
                }
            },
            {
                "PutRequest": {
                    "Item": {
                        "id": {"S": "003"},
                        "name": {"S": "Third Item"}
                    }
                }
            }
        ]
    }' \
    --profile dynamodb-dev
```

### Query Data

```bash
# Get item by key
aws dynamodb get-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Scan entire table
aws dynamodb scan \
    --table-name TestTable \
    --profile dynamodb-dev

# Query with condition
aws dynamodb query \
    --table-name TestTable \
    --key-condition-expression "id = :id" \
    --expression-attribute-values '{":id": {"S": "001"}}' \
    --profile dynamodb-dev

# Scan with filter
aws dynamodb scan \
    --table-name TestTable \
    --filter-expression "attribute_exists(#n)" \
    --expression-attribute-names '{"#n": "name"}' \
    --profile dynamodb-dev
```

### Update Data

```bash
# Update item
aws dynamodb update-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --update-expression "SET #n = :name, #d = :desc" \
    --expression-attribute-names '{
        "#n": "name",
        "#d": "description"
    }' \
    --expression-attribute-values '{
        ":name": {"S": "Updated Name"},
        ":desc": {"S": "Updated Description"}
    }' \
    --return-values ALL_NEW \
    --profile dynamodb-dev
```

### Delete Data

```bash
# Delete single item
aws dynamodb delete-item \
    --table-name TestTable \
    --key '{"id": {"S": "001"}}' \
    --profile dynamodb-dev

# Delete table
aws dynamodb delete-table \
    --table-name TestTable \
    --profile dynamodb-dev
```

---

## Advanced DynamoDB Operations

### Create Table with Global Secondary Index (GSI)

```bash
aws dynamodb create-table \
    --table-name UsersTable \
    --attribute-definitions \
        AttributeName=userId,AttributeType=S \
        AttributeName=email,AttributeType=S \
        AttributeName=createdAt,AttributeType=N \
    --key-schema \
        AttributeName=userId,KeyType=HASH \
    --global-secondary-indexes \
        "[
            {
                \"IndexName\": \"EmailIndex\",
                \"KeySchema\": [
                    {\"AttributeName\": \"email\", \"KeyType\": \"HASH\"}
                ],
                \"Projection\": {
                    \"ProjectionType\": \"ALL\"
                }
            },
            {
                \"IndexName\": \"CreatedAtIndex\",
                \"KeySchema\": [
                    {\"AttributeName\": \"createdAt\", \"KeyType\": \"HASH\"}
                ],
                \"Projection\": {
                    \"ProjectionType\": \"ALL\"
                }
            }
        ]" \
    --billing-mode PAY_PER_REQUEST \
    --profile dynamodb-dev
```

### Query Using GSI

```bash
# Query by email using GSI
aws dynamodb query \
    --table-name UsersTable \
    --index-name EmailIndex \
    --key-condition-expression "email = :email" \
    --expression-attribute-values '{":email": {"S": "user@example.com"}}' \
    --profile dynamodb-dev
```

### Conditional Writes

```bash
# Put item only if it doesn't exist
aws dynamodb put-item \
    --table-name TestTable \
    --item '{
        "id": {"S": "004"},
        "name": {"S": "Conditional Item"}
    }' \
    --condition-expression "attribute_not_exists(id)" \
    --profile dynamodb-dev

# Update item only if attribute has specific value
aws dynamodb update-item \
    --table-name TestTable \
    --key '{"id": {"S": "004"}}' \
    --update-expression "SET #n = :newname" \
    --condition-expression "#n = :oldname" \
    --expression-attribute-names '{"#n": "name"}' \
    --expression-attribute-values '{
        ":newname": {"S": "New Name"},
        ":oldname": {"S": "Conditional Item"}
    }' \
    --profile dynamodb-dev
```

---

## Utility Scripts

### Script 1: Auto-Login Helper

```bash
#!/bin/bash
# File: aws-sso-login.sh
# Usage: ./aws-sso-login.sh

PROFILE="dynamodb-dev"

echo "Checking AWS SSO credentials..."

if aws sts get-caller-identity --profile $PROFILE &>/dev/null; then
    echo "✅ SSO credentials are valid"
    aws sts get-caller-identity --profile $PROFILE
else
    echo "⚠️  SSO credentials expired or not found"
    echo "Logging in..."
    aws sso login --profile $PROFILE
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged in"
        aws sts get-caller-identity --profile $PROFILE
    else
        echo "❌ Login failed"
        exit 1
    fi
fi
```

### Script 2: DynamoDB Table Manager

```bash
#!/bin/bash
# File: dynamodb-manager.sh
# Usage: ./dynamodb-manager.sh [list|create|delete|describe] [table-name]

PROFILE="dynamodb-dev"
ACTION=$1
TABLE_NAME=$2

case $ACTION in
    list)
        echo "Listing all DynamoDB tables..."
        aws dynamodb list-tables --profile $PROFILE
        ;;
    create)
        if [ -z "$TABLE_NAME" ]; then
            echo "Error: Table name required"
            echo "Usage: $0 create <table-name>"
            exit 1
        fi
        echo "Creating table: $TABLE_NAME"
        aws dynamodb create-table \
            --table-name $TABLE_NAME \
            --attribute-definitions AttributeName=id,AttributeType=S \
            --key-schema AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --profile $PROFILE
        ;;
    delete)
        if [ -z "$TABLE_NAME" ]; then
            echo "Error: Table name required"
            echo "Usage: $0 delete <table-name>"
            exit 1
        fi
        echo "Deleting table: $TABLE_NAME"
        aws dynamodb delete-table --table-name $TABLE_NAME --profile $PROFILE
        ;;
    describe)
        if [ -z "$TABLE_NAME" ]; then
            echo "Error: Table name required"
            echo "Usage: $0 describe <table-name>"
            exit 1
        fi
        echo "Describing table: $TABLE_NAME"
        aws dynamodb describe-table --table-name $TABLE_NAME --profile $PROFILE
        ;;
    *)
        echo "Usage: $0 [list|create|delete|describe] [table-name]"
        exit 1
        ;;
esac
```

### Script 3: Bulk Data Loader

```bash
#!/bin/bash
# File: load-sample-data.sh
# Usage: ./load-sample-data.sh <table-name>

PROFILE="dynamodb-dev"
TABLE_NAME=$1

if [ -z "$TABLE_NAME" ]; then
    echo "Error: Table name required"
    echo "Usage: $0 <table-name>"
    exit 1
fi

echo "Loading sample data into $TABLE_NAME..."

# Load 10 sample items
for i in {1..10}; do
    ID=$(printf "%03d" $i)
    echo "Inserting item $ID..."
    
    aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "{
            \"id\": {\"S\": \"$ID\"},
            \"name\": {\"S\": \"Item $i\"},
            \"value\": {\"N\": \"$((RANDOM % 1000))\"},
            \"timestamp\": {\"N\": \"$(date +%s)\"}
        }" \
        --profile $PROFILE
done

echo "✅ Loaded 10 items successfully"
```

---

## Python SDK Examples

### Setup

```bash
# Install boto3
pip install boto3
```

### Example 1: Basic Operations

```python
# File: dynamodb_basic.py
import boto3
from boto3.dynamodb.conditions import Key, Attr

# Create session using SSO profile
session = boto3.Session(profile_name='dynamodb-dev')
dynamodb = session.resource('dynamodb')

# Get table
table = dynamodb.Table('TestTable')

# Put item
response = table.put_item(
    Item={
        'id': '001',
        'name': 'Python Item',
        'description': 'Created from Python',
        'value': 100
    }
)
print("Put item:", response)

# Get item
response = table.get_item(Key={'id': '001'})
item = response.get('Item')
print("Get item:", item)

# Update item
response = table.update_item(
    Key={'id': '001'},
    UpdateExpression='SET #v = #v + :inc',
    ExpressionAttributeNames={'#v': 'value'},
    ExpressionAttributeValues={':inc': 10},
    ReturnValues='ALL_NEW'
)
print("Updated item:", response['Attributes'])

# Query items
response = table.query(
    KeyConditionExpression=Key('id').eq('001')
)
print("Query results:", response['Items'])

# Scan with filter
response = table.scan(
    FilterExpression=Attr('value').gt(50)
)
print("Scan results:", response['Items'])

# Delete item
response = table.delete_item(Key={'id': '001'})
print("Delete item:", response)
```

### Example 2: Batch Operations

```python
# File: dynamodb_batch.py
import boto3

session = boto3.Session(profile_name='dynamodb-dev')
dynamodb = session.resource('dynamodb')
table = dynamodb.Table('TestTable')

# Batch write
with table.batch_writer() as batch:
    for i in range(100):
        batch.put_item(
            Item={
                'id': f'{i:03d}',
                'name': f'Batch Item {i}',
                'value': i * 10
            }
        )
print("Batch write complete")

# Batch get
response = dynamodb.batch_get_item(
    RequestItems={
        'TestTable': {
            'Keys': [
                {'id': '001'},
                {'id': '002'},
                {'id': '003'}
            ]
        }
    }
)
print("Batch get results:", response['Responses']['TestTable'])
```

---

## Troubleshooting Commands

### Check SSO Status

```bash
# Check if logged in
aws sts get-caller-identity --profile dynamodb-dev

# List SSO sessions
ls -la ~/.aws/sso/cache/

# View SSO configuration
cat ~/.aws/config | grep -A 10 "profile dynamodb-dev"
```

### Re-authenticate

```bash
# Logout
aws sso logout --profile dynamodb-dev

# Login again
aws sso login --profile dynamodb-dev
```

### Clear SSO Cache

```bash
# Remove cached credentials
rm -rf ~/.aws/sso/cache/*
rm -rf ~/.aws/cli/cache/*

# Login again
aws sso login --profile dynamodb-dev
```

### Debug Mode

```bash
# Run commands with debug output
aws dynamodb list-tables --profile dynamodb-dev --debug

# Check CloudTrail for API calls
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::DynamoDB::Table \
    --max-results 10 \
    --profile dynamodb-dev
```

---

## Environment Variables

### Set Default Profile

```bash
# Add to ~/.bashrc or ~/.zshrc
export AWS_PROFILE=dynamodb-dev

# Now you can omit --profile flag
aws dynamodb list-tables
```

### Set Default Region

```bash
export AWS_DEFAULT_REGION=us-east-1
```

### Create Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias aws-login='aws sso login --profile dynamodb-dev'
alias aws-whoami='aws sts get-caller-identity --profile dynamodb-dev'
alias ddb-list='aws dynamodb list-tables --profile dynamodb-dev'
alias ddb-scan='aws dynamodb scan --table-name'
```

---

## Complete Setup Checklist

```
□ Install AWS CLI v2
□ Enable IAM Identity Center in AWS Console
□ Create user in Identity Center
□ Create DynamoDB permission set
□ Assign user to AWS account with permission set
□ Configure SSO profile locally (aws configure sso)
□ Login via SSO (aws sso login)
□ Verify access (aws sts get-caller-identity)
□ Test DynamoDB access (aws dynamodb list-tables)
□ Create test table
□ Insert sample data
□ Query data
□ Enable MFA (optional but recommended)
□ Set up environment variables
□ Create utility scripts
□ Test Python SDK (optional)
```

---

## Quick Reference Card

```bash
# Login
aws sso login --profile dynamodb-dev

# Check identity
aws sts get-caller-identity --profile dynamodb-dev

# List tables
aws dynamodb list-tables --profile dynamodb-dev

# Create table
aws dynamodb create-table --table-name MyTable \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST --profile dynamodb-dev

# Put item
aws dynamodb put-item --table-name MyTable \
    --item '{"id": {"S": "001"}, "name": {"S": "Test"}}' \
    --profile dynamodb-dev

# Get item
aws dynamodb get-item --table-name MyTable \
    --key '{"id": {"S": "001"}}' --profile dynamodb-dev

# Scan table
aws dynamodb scan --table-name MyTable --profile dynamodb-dev

# Delete table
aws dynamodb delete-table --table-name MyTable --profile dynamodb-dev
```

---

## Support Resources

- **AWS CLI Documentation**: https://docs.aws.amazon.com/cli/
- **DynamoDB Developer Guide**: https://docs.aws.amazon.com/dynamodb/
- **IAM Identity Center**: https://docs.aws.amazon.com/singlesignon/
- **Boto3 Documentation**: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html

---

**All code is ready to copy and execute on your separate server!**
