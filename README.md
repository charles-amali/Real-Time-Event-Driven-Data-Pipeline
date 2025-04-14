# E-Commerce Real-Time Analytics Pipeline
A production-grade, event-driven data pipeline that processes e-commerce transaction data in real-time using AWS services. The pipeline validates incoming data, transforms it into business KPIs, and stores results for real-time querying.

## Architecture Overview
![Architecture Diagram](architecture_ecs.jpg)
The pipeline consists of the following components:
- **S3**: Stores incoming transaction data files
- **ECS**: Runs containerized validation and transformation tasks
- **Step Functions**: Orchestrates the entire workflow
- **DynamoDB**: Stores computed KPIs for real-time access

## Data Format and Schema
### Input Data Files
The pipeline processes three types of CSV files:
1. **Orders** :```csv
order_id, user_id, created_at, status, shipped_at, delivered_at, returned_at, num_of_item
```
2. **Order Items** :```csv
id, order_id, product_id, status, created_at, shipped_at, delivered_at, returned_at, sale_price
```
3. **Products**:```csv
id, sku, cost, category, name, brand, retail_price, department
```

### Validation Rules
- **Orders**: Required fields - order_id, user_id, created_at, status
- **Order Items**: Required fields - id, order_id, product_id, sale_price
- **Products**: Required fields - id, sku, cost, category, retail_price
- Referential integrity between order_items.order_id and orders.order_id
- Valid date formats and numeric values

## DynamoDB Schema
### Category KPIs Table
- **Table Name**: `category_kpi_table`
- **Partition Key**: category (String)
- **Sort Key**: order_date (String)
- **Attributes**:
  - daily_revenue (Number)  
  - avg_order_value (Number)
  - avg_return_rate (Number)

### Order KPIs Table
- **Table Name**: `order_kpi_table`
- **Partition Key**: order_date (String)
- **Attributes**:  
  - total_orders (Number)
  - total_revenue (Number)  
  - total_items_sold (Number)
  - return_rate (Number) 
  - unique_customers (Number)

## Step Functions Workflow
1. **Data Validation** (`RunValidationTask`):
   - Validates input files using ECS task  
   - On success: Proceeds to transformation
   - On failure: Moves data to invalid-data archive
2. **Data Transformation** (`RunTransformationTask`):  
   - Computes KPIs using ECS task
   - Stores results in DynamoDB   
   - Handles failures with retry logic

## Error Handling and Monitoring
- CloudWatch Logs for ECS tasks
- SNS notifications for pipeline failures- Dead-letter queues for failed processing
- Automatic retry mechanism for transient failures

## Deployment Instructions
1. **Build and Push Docker Images**:```bash
# From project rootcd Docker_images/validation_image
docker build -t spark-validate .cd ../transformation_image
docker build -t spark-transform .
# Push to ECR./push_to_cloud.sh
```
2. **Deploy Infrastructure**:```bash
# Set up ECR repositories, ECS cluster, and log groupsaws cloudformation deploy --template-file infrastructure.yaml --stack-name ecommerce-pipeline
```
3. **Configure Environment Variables**:```bash
# Create .env file with required variablesAWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secretAWS_DEFAULT_REGION=your_region
BUCKET_NAME=your_bucket```
## Manual Testing
1. **Upload Test Data**:
```bashaws s3 cp test_data/orders.csv s3://your-bucket/landing-data/orders/
aws s3 cp test_data/order_items.csv s3://your-bucket/landing-data/order_items/
aws s3 cp test_data/products.csv s3://your-bucket/landing-data/products.csv
```
2. **Monitor Processing**:```bash
# Check ECS task statusaws ecs list-tasks --cluster ecommerce-cluster
# View CloudWatch logs
aws logs get-log-events --log-group-name /ecs/validate-task```
3. **Verify Results**:
```bash# Query DynamoDB tables
aws dynamodb query \    
    --table-name category_kpi_table \
    --key-condition-expression "category = :cat AND order_date = :date" \    
    --expression-attribute-values '{":cat":{"S":"Electronics"},":date":{"S":"2023-01-01"}}'
```
## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.
## License

This project is licensed under the MIT License - see the LICENSE file for details.











































































