#!/usr/bin/env python3
"""
DynamoDB Basic Operations using Boto3
Usage: python3 dynamodb_basic.py
"""

import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
import json

# Configuration
PROFILE_NAME = 'dynamodb-dev'
TABLE_NAME = 'TestTable'

def create_session():
    """Create boto3 session using SSO profile"""
    try:
        session = boto3.Session(profile_name=PROFILE_NAME)
        return session
    except Exception as e:
        print(f"❌ Error creating session: {e}")
        print("Make sure you've run: aws sso login --profile dynamodb-dev")
        exit(1)

def get_table(session, table_name):
    """Get DynamoDB table resource"""
    dynamodb = session.resource('dynamodb')
    return dynamodb.Table(table_name)

def put_item_example(table):
    """Put item into DynamoDB table"""
    print("\n📝 Putting item...")
    try:
        response = table.put_item(
            Item={
                'id': '001',
                'name': 'Python Item',
                'description': 'Created from Python SDK',
                'value': 100,
                'tags': ['python', 'boto3', 'dynamodb']
            }
        )
        print("✅ Item created successfully")
        return response
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return None

def get_item_example(table):
    """Get item from DynamoDB table"""
    print("\n🔍 Getting item...")
    try:
        response = table.get_item(Key={'id': '001'})
        item = response.get('Item')
        if item:
            print("✅ Item retrieved:")
            print(json.dumps(item, indent=2, default=str))
        else:
            print("⚠️  Item not found")
        return item
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return None

def update_item_example(table):
    """Update item in DynamoDB table"""
    print("\n✏️  Updating item...")
    try:
        response = table.update_item(
            Key={'id': '001'},
            UpdateExpression='SET #v = #v + :inc, #desc = :new_desc',
            ExpressionAttributeNames={
                '#v': 'value',
                '#desc': 'description'
            },
            ExpressionAttributeValues={
                ':inc': 50,
                ':new_desc': 'Updated from Python SDK'
            },
            ReturnValues='ALL_NEW'
        )
        print("✅ Item updated successfully:")
        print(json.dumps(response['Attributes'], indent=2, default=str))
        return response
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return None

def query_example(table):
    """Query items from DynamoDB table"""
    print("\n🔎 Querying items...")
    try:
        response = table.query(
            KeyConditionExpression=Key('id').eq('001')
        )
        items = response.get('Items', [])
        print(f"✅ Found {len(items)} item(s):")
        for item in items:
            print(json.dumps(item, indent=2, default=str))
        return items
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return []

def scan_example(table):
    """Scan table with filter"""
    print("\n📊 Scanning table with filter...")
    try:
        response = table.scan(
            FilterExpression=Attr('value').gt(50)
        )
        items = response.get('Items', [])
        print(f"✅ Found {len(items)} item(s) with value > 50:")
        for item in items:
            print(f"  - ID: {item['id']}, Value: {item['value']}")
        return items
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return []

def delete_item_example(table):
    """Delete item from DynamoDB table"""
    print("\n🗑️  Deleting item...")
    try:
        response = table.delete_item(
            Key={'id': '001'},
            ReturnValues='ALL_OLD'
        )
        deleted_item = response.get('Attributes')
        if deleted_item:
            print("✅ Item deleted successfully:")
            print(json.dumps(deleted_item, indent=2, default=str))
        return response
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")
        return None

def batch_write_example(table):
    """Batch write multiple items"""
    print("\n📦 Batch writing items...")
    try:
        with table.batch_writer() as batch:
            for i in range(1, 6):
                batch.put_item(
                    Item={
                        'id': f'{i:03d}',
                        'name': f'Batch Item {i}',
                        'value': i * 10,
                        'category': f'Category {i % 3 + 1}'
                    }
                )
        print("✅ Batch write completed (5 items)")
    except ClientError as e:
        print(f"❌ Error: {e.response['Error']['Message']}")

def main():
    """Main function"""
    print("=" * 50)
    print("DynamoDB Basic Operations Demo")
    print("=" * 50)
    
    # Create session
    session = create_session()
    print(f"✅ Session created with profile: {PROFILE_NAME}")
    
    # Get table
    table = get_table(session, TABLE_NAME)
    print(f"✅ Connected to table: {TABLE_NAME}")
    
    # Run examples
    put_item_example(table)
    get_item_example(table)
    update_item_example(table)
    query_example(table)
    batch_write_example(table)
    scan_example(table)
    
    # Cleanup (optional - uncomment to delete test item)
    # delete_item_example(table)
    
    print("\n" + "=" * 50)
    print("✅ Demo completed successfully!")
    print("=" * 50)

if __name__ == "__main__":
    main()
