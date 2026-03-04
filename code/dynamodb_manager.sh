#!/bin/bash
# DynamoDB Table Manager
# Usage: ./dynamodb-manager.sh [list|create|delete|describe|scan] [table-name]

PROFILE="dynamodb-dev"
ACTION=$1
TABLE_NAME=$2

echo "=========================================="
echo "DynamoDB Table Manager"
echo "=========================================="
echo ""

case $ACTION in
    list)
        echo "📋 Listing all DynamoDB tables..."
        echo ""
        aws dynamodb list-tables --profile $PROFILE
        ;;
    
    create)
        if [ -z "$TABLE_NAME" ]; then
            echo "❌ Error: Table name required"
            echo "Usage: $0 create <table-name>"
            exit 1
        fi
        echo "🔨 Creating table: $TABLE_NAME"
        echo ""
        aws dynamodb create-table \
            --table-name $TABLE_NAME \
            --attribute-definitions AttributeName=id,AttributeType=S \
            --key-schema AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --profile $PROFILE
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "⏳ Waiting for table to become active..."
            aws dynamodb wait table-exists --table-name $TABLE_NAME --profile $PROFILE
            echo "✅ Table created successfully"
        fi
        ;;
    
    delete)
        if [ -z "$TABLE_NAME" ]; then
            echo "❌ Error: Table name required"
            echo "Usage: $0 delete <table-name>"
            exit 1
        fi
        echo "🗑️  Deleting table: $TABLE_NAME"
        echo ""
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            aws dynamodb delete-table --table-name $TABLE_NAME --profile $PROFILE
            echo "✅ Table deletion initiated"
        else
            echo "❌ Deletion cancelled"
        fi
        ;;
    
    describe)
        if [ -z "$TABLE_NAME" ]; then
            echo "❌ Error: Table name required"
            echo "Usage: $0 describe <table-name>"
            exit 1
        fi
        echo "📊 Describing table: $TABLE_NAME"
        echo ""
        aws dynamodb describe-table --table-name $TABLE_NAME --profile $PROFILE
        ;;
    
    scan)
        if [ -z "$TABLE_NAME" ]; then
            echo "❌ Error: Table name required"
            echo "Usage: $0 scan <table-name>"
            exit 1
        fi
        echo "🔍 Scanning table: $TABLE_NAME"
        echo ""
        aws dynamodb scan --table-name $TABLE_NAME --profile $PROFILE
        ;;
    
    *)
        echo "Usage: $0 [list|create|delete|describe|scan] [table-name]"
        echo ""
        echo "Commands:"
        echo "  list              - List all tables"
        echo "  create <name>     - Create a new table"
        echo "  delete <name>     - Delete a table"
        echo "  describe <name>   - Describe table details"
        echo "  scan <name>       - Scan all items in table"
        exit 1
        ;;
esac

echo ""
echo "=========================================="

