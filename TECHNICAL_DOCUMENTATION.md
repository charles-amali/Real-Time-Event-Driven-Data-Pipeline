# E-Commerce Real-Time Analytics Pipeline

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
   - [Data Flow](#data-flow)
   - [Core Components](#core-components)
3. [Data Processing](#data-processing)
   - [Input Data Format](#input-data-format)
   - [Data Validation](#data-validation)
   - [KPI Computation](#kpi-computation)
4. [Infrastructure](#infrastructure)
   - [Container Services](#container-services)
   - [Storage Solutions](#storage-solutions)
5. [Deployment Guide](#deployment-guide)
6. [Monitoring and Error Handling](#monitoring-and-error-handling)
7. [Performance Optimization](#performance-optimization)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

## Overview
This production-grade data pipeline processes e-commerce transaction data in real-time using AWS services. The system validates incoming data, computes business KPIs, and stores results for real-time querying.

Key Features:
- Real-time data processing
- Automated data validation
- Business KPI computation
- Scalable architecture
- Error handling and monitoring

## System Architecture

### Data Flow
1. Data ingestion through S3
2. Validation using PySpark
3. KPI computation
4. Storage in DynamoDB
5. Error handling and archival

### Core Components
1. **Data Ingestion (S3)**
   - Landing zone: `s3://bucket-name/ecommerce-data/`
   - Structured directory organization for different data types:
     ```
     ecommerce-data/
     ├── orders/
     │   └── orders_part1.csv
     ├── order_items/
     │   └── order-items_part1.csv
     └── products/
         └── products.csv
     ```

2. **Processing Layer**
   - Validation container: PySpark-based data quality checks
   - Transformation container: KPI computation and aggregation
   - Container specifications:
     - Memory: 3GB
     - vCPU: 1
     - Timeout: 900 seconds

3. **Storage Layer**
   - Primary storage: DynamoDB
   - Archive storage: S3 (`s3://bucket-name/archive/`)
   - Error storage: S3 (`s3://bucket-name/err/`)

## Data Processing

### Input Data Format

#### Orders Schema
```python
# Orders Schema - Core transaction data
orders_schema = StructType([
    StructField("order_id", StringType(), nullable=False),
    StructField("user_id", StringType(), nullable=False),
    StructField("created_at", TimestampType(), nullable=False),
    StructField("status", StringType(), nullable=False),
    StructField("shipped_at", TimestampType(), nullable=True),
    StructField("delivered_at", TimestampType(), nullable=True),
    StructField("returned_at", TimestampType(), nullable=True),
    StructField("num_of_item", IntegerType(), nullable=True)
])
```

### Data Validation

#### Quality Checks
1. **Required Fields**
   - Orders: `order_id`, `user_id`, `created_at`, `status`
   - Order Items: `id`, `order_id`, `product_id`, `sale_price`

2. **Referential Integrity**
```python
def validate_references(orders_df, items_df):
    valid_orders = orders_df.select("order_id").distinct()
    return items_df.join(valid_orders, "order_id", "inner")
```

3. **Business Logic Validation**
   ```python
   def validate_dates(df):
       return df.filter(
           (col("shipped_at").isNull()) | 
           (col("shipped_at") >= col("created_at"))
       )
   ```

### KPI Computation

#### Category Metrics
```python
def compute_category_kpis(joint_df):
    return joint_df.groupBy("category", "order_date").agg(
        round(sum("sale_price"), 2).alias("daily_revenue"),
        round(avg("sale_price"), 2).alias("avg_order_value"),
        round(sum(when(col("status") == "returned", 1).otherwise(0)) / 
             count("order_id"), 4).alias("return_rate")
    )
```

#### Order Metrics
```python
def compute_order_kpis(joint_df):
    return joint_df.groupBy("order_date").agg(
        countDistinct("order_id").alias("total_orders"),
        sum("sale_price").alias("total_revenue"),
        count("item_id").alias("total_items_sold"),
        countDistinct("user_id").alias("unique_customers")
    )
```

## Infrastructure

### Container Services

#### Validation Container
```dockerfile
FROM python:3.9-slim
ENV SPARK_VERSION=3.3.2
ENV HADOOP_VERSION=3

RUN pip install pyspark boto3 python-dotenv
```

#### Transformation Container
- Base: python:3.9-slim
- Dependencies: pyspark, boto3, python-dotenv
- Optimized for aggregation operations

### Storage Solutions

#### DynamoDB Tables

1. Category KPIs Table
```json
{
    "TableName": "category_kpi_table",
    "KeySchema": [
        {"AttributeName": "category", "KeyType": "HASH"},
        {"AttributeName": "order_date", "KeyType": "RANGE"}
    ],
    "AttributeDefinitions": [
        {"AttributeName": "category", "AttributeType": "S"},
        {"AttributeName": "order_date", "AttributeType": "S"}
    ],
    "BillingMode": "PAY_PER_REQUEST"
}
```

2. Order KPIs Table
```json
{
    "TableName": "order_kpi_table",
    "KeySchema": [
        {"AttributeName": "order_date", "KeyType": "HASH"}
    ],
    "AttributeDefinitions": [
        {"AttributeName": "order_date", "AttributeType": "S"}
    ],
    "BillingMode": "PAY_PER_REQUEST"
}
```

## Deployment Guide

### Container Deployment
```bash
# Build containers
cd Docker_images/validation_image
docker build -t spark-validate .
cd ../transformation_image
docker build -t spark-transform .

# Deploy to ECR
./push_to_cloud.sh
```

### Infrastructure Setup
```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name ecommerce-pipeline-cluster

# Create log groups
aws logs create-log-group --log-group-name /ecs/validate-task
aws logs create-log-group --log-group-name /ecs/transform-task
```

## Monitoring and Error Handling

### Error Management
- Failed records: `s3://bucket-name/error/`
- Archive: `s3://bucket-name/archive/`
- CloudWatch Logs integration
- SNS notifications

### Monitoring Metrics
- Processing latency
- ECS task status
- DynamoDB throughput
- Validation failure rates

## Performance Optimization

### Container Configuration
- Memory: 3GB per container
- CPU: 1 vCPU per container
- PySpark optimizations

### DynamoDB Best Practices
- Efficient partition keys
- Batch operations
- On-demand capacity

## Security

### Data Protection
- S3 encryption
- DynamoDB encryption
- VPC isolation

### Access Control
- IAM roles
- Least privilege
- Resource policies

## Troubleshooting

### Common Issues
1. **ECS Tasks**
   - CloudWatch Logs
   - Resource allocation
   - Container health

2. **Data Quality**
   - Validation logs
   - Error directory
   - Input format

3. **Performance**
   - DynamoDB metrics
   - ECS resources
   - Processing latency

## API Reference

### DynamoDB Queries
```bash
# Query category KPIs
aws dynamodb query \
    --table-name category_kpi_table \
    --key-condition-expression "category = :cat" \
    --expression-attribute-values '{":cat":{"S":"Electronics"}}'

# Query order KPIs
aws dynamodb query \
    --table-name order_kpi_table \
    --key-condition-expression "order_date = :date" \
    --expression-attribute-values '{":date":{"S":"2023-01-01"}}'
```



