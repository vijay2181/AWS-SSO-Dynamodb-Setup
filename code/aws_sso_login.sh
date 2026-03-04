#!/bin/bash
# AWS SSO Auto-Login Helper
# Usage: ./aws-sso-login.sh

PROFILE="dynamodb-dev"

echo "=========================================="
echo "AWS SSO Login Helper"
echo "=========================================="
echo ""
echo "Checking AWS SSO credentials for profile: $PROFILE"
echo ""

if aws sts get-caller-identity --profile $PROFILE &>/dev/null; then
    echo "✅ SSO credentials are valid"
    echo ""
    echo "Current Identity:"
    aws sts get-caller-identity --profile $PROFILE
else
    echo "⚠️  SSO credentials expired or not found"
    echo ""
    echo "Initiating SSO login..."
    aws sso login --profile $PROFILE
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Successfully logged in"
        echo ""
        echo "Current Identity:"
        aws sts get-caller-identity --profile $PROFILE
    else
        echo ""
        echo "❌ Login failed"
        exit 1
    fi
fi

echo ""
echo "=========================================="
