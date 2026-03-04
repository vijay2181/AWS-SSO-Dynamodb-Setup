#!/bin/bash
# Bulk Data Loader for DynamoDB
# Usage: ./load-sample-data.sh <table-name> [number-of-items]

PROFILE="dynamodb-dev"
TABLE_NAME=$1
NUM_ITEMS=${2:-10}  # Default to 10 items

echo "=========================================="
echo "DynamoDB Sample Data Loader"
echo "=========================================="
echo ""

if [ -z "$TABLE_NAME" ]; then
    echo "❌ Error: Table name required"
    echo "Usage: $0 <table-name> [number-of-items]"
    echo "Example: $0 TestTable 20"
    exit 1
fi

echo "📊 Loading $NUM_ITEMS sample items into table: $TABLE_NAME"
echo ""

# Check if table exists
if ! aws dynamodb describe-table --table-name $TABLE_NAME --profile $PROFILE &>/dev/null; then
    echo "❌ Error: Table '$TABLE_NAME' does not exist"
    exit 1
fi

SUCCESS_COUNT=0
FAIL_COUNT=0

# Load sample items
for i in $(seq 1 $NUM_ITEMS); do
    ID=$(printf "%03d" $i)
    RANDOM_VALUE=$((RANDOM % 1000))
    TIMESTAMP=$(date +%s)
    
    echo -n "Inserting item $ID... "
    
    if aws dynamodb put-item \
        --table-name $TABLE_NAME \
        --item "{
            \"id\": {\"S\": \"$ID\"},
            \"name\": {\"S\": \"Sample Item $i\"},
            \"value\": {\"N\": \"$RANDOM_VALUE\"},
            \"category\": {\"S\": \"Category $((i % 5 + 1))\"},
            \"timestamp\": {\"N\": \"$TIMESTAMP\"},
            \"active\": {\"BOOL\": true}
        }" \
        --profile $PROFILE &>/dev/null; then
        echo "✅"
        ((SUCCESS_COUNT++))
    else
        echo "❌"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo "=========================================="
echo "Summary:"
echo "  ✅ Successfully loaded: $SUCCESS_COUNT items"
echo "  ❌ Failed: $FAIL_COUNT items"
echo "=========================================="
echo ""

# Show sample of loaded data
echo "Sample of loaded data:"
aws dynamodb scan \
    --table-name $TABLE_NAME \
    --max-items 5 \
    --profile $PROFILE \
    --query 'Items[*].[id.S, name.S, value.N]' \
    --output table

echo ""
echo "✅ Data loading complete!"

