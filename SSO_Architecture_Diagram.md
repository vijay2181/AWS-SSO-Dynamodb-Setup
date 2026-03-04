# AWS SSO + DynamoDB Architecture

## High-Level Architecture

```mermaid
graph TB
    subgraph "Local Machine"
        A[Developer] -->|1. aws sso login| B[AWS CLI v2]
        B -->|Opens Browser| C[Web Browser]
    end
    
    subgraph "AWS Cloud"
        C -->|2. Authenticate| D[IAM Identity Center<br/>SSO Portal]
        D -->|3. Verify Credentials| E[Identity Store]
        E -->|4. Return Token| D
        D -->|5. Temporary Credentials| B
        
        B -->|6. API Calls with<br/>Temp Credentials| F[AWS STS]
        F -->|7. Assume Role| G[DynamoDB Permission Set]
        G -->|8. Authorized Access| H[DynamoDB Service]
        
        subgraph "DynamoDB"
            H --> I[Tables]
            I --> J[Items/Data]
        end
    end
    
    style A fill:#e1f5ff
    style D fill:#ff9900
    style H fill:#527FFF
    style B fill:#90EE90
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant CLI as AWS CLI
    participant Browser as Web Browser
    participant SSO as IAM Identity Center
    participant STS as AWS STS
    participant DDB as DynamoDB

    Dev->>CLI: aws sso login --profile dynamodb-dev
    CLI->>Browser: Open SSO Portal URL
    Browser->>SSO: Navigate to Portal
    SSO->>Browser: Display Login Page
    Dev->>Browser: Enter Credentials + MFA
    Browser->>SSO: Submit Authentication
    SSO->>Browser: Authorization Code
    Browser->>CLI: Return Authorization Code
    CLI->>SSO: Exchange Code for Token
    SSO->>CLI: Return Access Token
    CLI->>STS: Request Temporary Credentials
    STS->>CLI: Return Temp Credentials (12h)
    
    Note over CLI: Credentials Cached Locally
    
    Dev->>CLI: aws dynamodb list-tables
    CLI->>DDB: API Call with Temp Credentials
    DDB->>CLI: Return Table List
    CLI->>Dev: Display Results
```

## Component Details

### 1. Local Machine Components

```
┌─────────────────────────────────────────┐
│         Local Machine (macOS)           │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │       AWS CLI v2                 │  │
│  │  - SSO Authentication            │  │
│  │  - Credential Management         │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   ~/.aws/config                  │  │
│  │  [profile dynamodb-dev]          │  │
│  │  sso_session = my-sso            │  │
│  │  sso_account_id = 123456789012   │  │
│  │  sso_role_name = DynamoDBAccess  │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   ~/.aws/sso/cache/              │  │
│  │  - Cached SSO tokens             │  │
│  │  - Temporary credentials         │  │
│  │  - Auto-expires after 12h        │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 2. AWS IAM Identity Center

```
┌─────────────────────────────────────────┐
│      IAM Identity Center (SSO)          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Identity Store                 │  │
│  │  - Users                         │  │
│  │  - Groups                        │  │
│  │  - MFA Settings                  │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Permission Sets                │  │
│  │  - DynamoDBFullAccess            │  │
│  │  - Session Duration: 12h         │  │
│  │  - IAM Policies Attached         │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Account Assignments            │  │
│  │  User → Account → Permission Set │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 3. AWS Account & DynamoDB

```
┌─────────────────────────────────────────┐
│          AWS Account                    │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   AWS STS (Security Token Svc)   │  │
│  │  - Issues Temporary Credentials  │  │
│  │  - Role Assumption               │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   DynamoDB Service               │  │
│  │                                  │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │  Tables                    │  │  │
│  │  │  - TestTable               │  │  │
│  │  │  - UsersTable              │  │  │
│  │  │  - ProductsTable           │  │  │
│  │  └────────────────────────────┘  │  │
│  │                                  │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │  Operations                │  │  │
│  │  │  - CreateTable             │  │  │
│  │  │  - PutItem                 │  │  │
│  │  │  - GetItem                 │  │  │
│  │  │  - Query                   │  │  │
│  │  │  - Scan                    │  │  │
│  │  └────────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   CloudTrail (Audit Logs)        │  │
│  │  - All API calls logged          │  │
│  │  - Who, What, When               │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Security Model

```mermaid
graph LR
    A[User Login] -->|MFA Optional| B[IAM Identity Center]
    B -->|Authenticate| C[Identity Store]
    C -->|Success| D[Generate Token]
    D -->|12h Session| E[Temporary Credentials]
    E -->|Assume Role| F[Permission Set]
    F -->|IAM Policy| G[DynamoDB Access]
    
    style A fill:#90EE90
    style B fill:#ff9900
    style E fill:#FFD700
    style G fill:#527FFF
```

### Security Layers

1. **Authentication Layer**
   - Username/Password
   - Optional MFA (TOTP/SMS)
   - Identity verification

2. **Authorization Layer**
   - Permission Sets (IAM Policies)
   - Least Privilege Access
   - Resource-level permissions

3. **Session Management**
   - Temporary credentials (12h default)
   - Automatic expiration
   - No long-term keys

4. **Audit Layer**
   - CloudTrail logging
   - All API calls tracked
   - Compliance reporting

## Data Flow: Creating a DynamoDB Table

```mermaid
flowchart TD
    A[Developer runs:<br/>aws dynamodb create-table] --> B{SSO Credentials<br/>Valid?}
    B -->|No| C[aws sso login]
    C --> D[Browser Authentication]
    D --> E[Get Temp Credentials]
    E --> B
    B -->|Yes| F[AWS CLI sends<br/>CreateTable API call]
    F --> G[AWS STS validates<br/>credentials]
    G --> H{Permission<br/>Check}
    H -->|Denied| I[Access Denied Error]
    H -->|Allowed| J[DynamoDB creates table]
    J --> K[Return Table ARN]
    K --> L[CLI displays success]
    
    style A fill:#e1f5ff
    style D fill:#ff9900
    style J fill:#527FFF
    style L fill:#90EE90
```

## Credential Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                  Credential Lifecycle                   │
└─────────────────────────────────────────────────────────┘

Time: 0h                    6h                    12h
│                           │                     │
├───────────────────────────┼─────────────────────┤
│   Credentials Valid       │  Still Valid        │ Expired
│                           │                     │
│   ✓ API calls work        │  ✓ API calls work   │ ✗ Need re-login
│   ✓ No re-auth needed     │  ✓ No re-auth       │ ✗ aws sso login
│                           │                     │
└───────────────────────────┴─────────────────────┘

After expiration:
1. Run: aws sso login --profile dynamodb-dev
2. Browser opens for re-authentication
3. New 12h session begins
```

## Comparison: Traditional vs SSO Authentication

### Traditional IAM User (Not Recommended)

```
┌──────────────┐
│  Developer   │
└──────┬───────┘
       │
       │ Long-term Access Keys
       │ (Never expire)
       │
       ▼
┌──────────────┐
│  AWS Account │
│              │
│  ┌────────┐  │
│  │DynamoDB│  │
│  └────────┘  │
└──────────────┘

❌ Security Risks:
- Keys never expire
- If leaked, permanent access
- Hard to rotate
- No MFA enforcement
```

### SSO with IAM Identity Center (Recommended)

```
┌──────────────┐
│  Developer   │
└──────┬───────┘
       │
       │ Browser-based login
       │ + Optional MFA
       │
       ▼
┌──────────────┐
│ IAM Identity │
│   Center     │
└──────┬───────┘
       │
       │ Temporary Credentials
       │ (12h expiration)
       │
       ▼
┌──────────────┐
│  AWS Account │
│              │
│  ┌────────┐  │
│  │DynamoDB│  │
│  └────────┘  │
└──────────────┘

✅ Security Benefits:
- Credentials auto-expire
- MFA support
- Centralized management
- Audit trail
- Easy to revoke
```

## Network Flow

```
Internet
   │
   │ HTTPS (443)
   │
   ▼
┌─────────────────────────┐
│  AWS Edge Locations     │
│  (CloudFront)           │
└────────┬────────────────┘
         │
         │ TLS 1.2+
         │
         ▼
┌─────────────────────────┐
│  IAM Identity Center    │
│  Regional Endpoint      │
│  (us-east-1)            │
└────────┬────────────────┘
         │
         │ Internal AWS Network
         │
         ▼
┌─────────────────────────┐
│  DynamoDB Service       │
│  Regional Endpoint      │
│  (us-east-1)            │
└─────────────────────────┘
```

## Permission Set Structure

```yaml
Permission Set: DynamoDBFullAccess
├── Name: DynamoDBFullAccess
├── Description: Full access to DynamoDB
├── Session Duration: 12 hours
├── Relay State: (optional)
└── Managed Policies:
    └── AmazonDynamoDBFullAccess
        ├── dynamodb:*
        ├── dax:*
        ├── application-autoscaling:*
        ├── cloudwatch:*
        ├── iam:GetRole
        ├── iam:ListRoles
        └── sns:*
```

## Multi-Account Architecture (Future)

```mermaid
graph TB
    A[IAM Identity Center<br/>Management Account] --> B[Dev Account]
    A --> C[Staging Account]
    A --> D[Production Account]
    
    B --> E[DynamoDB Dev]
    C --> F[DynamoDB Staging]
    D --> G[DynamoDB Production]
    
    H[Developer] -->|Single Login| A
    A -->|Different Permission Sets| B
    A -->|Different Permission Sets| C
    A -->|Different Permission Sets| D
    
    style A fill:#ff9900
    style H fill:#90EE90
    style E fill:#527FFF
    style F fill:#527FFF
    style G fill:#527FFF
```

## Summary

This architecture provides:

✅ **Secure Authentication**: Browser-based SSO with optional MFA  
✅ **Temporary Credentials**: Auto-expiring credentials (12h)  
✅ **Centralized Management**: Single place to manage users and permissions  
✅ **Audit Trail**: All actions logged in CloudTrail  
✅ **Scalable**: Easy to add accounts, users, and permissions  
✅ **Cost-Effective**: No additional charges for IAM Identity Center  

The architecture follows AWS best practices and provides a secure, scalable foundation for accessing DynamoDB and other AWS services.
