# Create ECR repositories
aws ecr create-repository --repository-name validate-data --region your-region
aws ecr create-repository --repository-name transform-data --region your-region
aws ecr create-repository --repository-name compute-kpis --region your-region

# Login to ECR
aws ecr get-login-password --region your-region \
| docker login --username AWS --password-stdin 123456789.dkr.ecr.your-region.amazonaws.com

# Validate-data
docker tag validate-data:latest 123456789.dkr.ecr.your-region.amazonaws.com/validate-data:latest
docker push 123456789.dkr.ecr.your-region.amazonaws.com/validate-data:latest

# Transform-data
docker tag transform-data:latest 123456789.dkr.ecr.your-region.amazonaws.com/transform-data:latest
docker push 123456789.dkr.ecr.your-region.amazonaws.com/transform-data:latest

# Compute-kpis
docker tag compute-kpis:latest 123456789.dkr.ecr.your-region.amazonaws.com/compute-kpis:latest
docker push 123456789.dkr.ecr.your-region.amazonaws.com/compute-kpis:latest

aws ecs create-cluster --cluster-name ecommerce-pipeline-cluster --region your-region

aws logs create-log-group --log-group-name /ecs/validate-task --region your-region
aws logs create-log-group --log-group-name /ecs/transform-task --region your-region
aws logs create-log-group --log-group-name /ecs/compute-task --region your-region


aws ecs register-task-definition --cli-input-json file://validate-task.json --region your-region
aws ecs register-task-definition --cli-input-json file://transform-task.json --region your-region
aws ecs register-task-definition --cli-input-json file://compute-task.json --region your-region

aws ec2 describe-vpcs --region your-region
aws ec2 describe-subnets --region your-region


aws ec2 create-security-group --group-name ecs-sg --description "ECS Security Group" --vpc-id vpc-123456 --region your-region
aws ec2 authorize-security-group-egress --group-id sg-123456789 --protocol "-1" --port -1 --cidr 0.0.0.0/0 --region your-region

# Transform (after validate succeeds)
aws ecs run-task --cluster ecommerce-pipeline-cluster --task-definition transform-task --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789 ],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" --region your-region

# Compute (after transform succeeds)
aws ecs run-task --cluster ecommerce-pipeline-cluster --task-definition compute-task --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789 ],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" --region your-region

# Validate
aws ecs run-task \
    --cluster ecommerce-pipeline-cluster \
    --task-definition validate-task \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" \
    --region your-region \
    --overrides '{
        "containerOverrides": [
            {
                "name": "validate-container",
                "command": [
                    "s3://your-bucket-name/temp/merge/order_items.csv"
                ]
            }
        ]
    }'


# Transform
aws ecs run-task \
    --cluster ecommerce-pipeline-cluster \
    --task-definition transform-task \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" \
    --region your-region \
    --overrides '{
        "containerOverrides": [
            {
                "name": "transform-container",
                "command": [
                    "s3://your-bucket-name/temp/merge/order_items.csv",
                    "s3://your-bucket-name/data/products.csv",
                    "s3://your-bucket-name/temp/transforms/order_items_transformed.csv"
                ]
            }
        ]
    }'


aws ecs run-task \
    --cluster ecommerce-pipeline-cluster \
    --task-definition transform-task \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" \
    --region your-region \
    --overrides '{
        "containerOverrides": [
            {
                "name": "transform-container",
                "command": [
                    "s3://your-bucket-name/temp/merge/orders.csv",
                    "none",
                    "s3://your-bucket-name/temp/transforms/orders_transformed.csv"
                ]
            }
        ]
    }'


aws ecs run-task \
    --cluster ecommerce-pipeline-cluster \
    --task-definition transform-task \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" \
    --region your-region \
    --overrides '{
        "containerOverrides": [
            {
                "name": "transform-container",
                "command": [
                    "s3://your-bucket-name/data/products.csv",
                    "none",
                    "s3://your-bucket-name/data/temp/transforms/products_transformed.csv"
                ]
            }
        ]
    }'


# compute
aws ecs run-task \
    --cluster ecommerce-pipeline-cluster \
    --task-definition compute-task \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-123456789,subnet-123456789],securityGroups=[sg-123456789],assignPublicIp=ENABLED}" \
    --region your-region \
    --overrides '{
        "containerOverrides": [
            {
                "name": "compute-container",
                "command": [
                    "s3://your-bucket-name/temp/transforms/order_items_transformed.csv",
                    "s3://your-bucket-name/temp/transforms/orders_transformed.csv",
                    "s3://your-bucket-name/output/kpis/category_kpis.csv",
                    "s3://your-bucket-name/output/kpis/order_kpis.csv"
                ]
            }
        ]
    }'