print("Script started...")
import boto3
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
if not load_dotenv():
    print("Failed to load .env file.")

AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_DEFAULT_REGION")

print("AWS_ACCESS_KEY:", AWS_ACCESS_KEY)
print("AWS_SECRET_KEY:", AWS_SECRET_KEY)
print("AWS_REGION:", AWS_REGION)


# Initialize S3 client with credentials from .env
s3 = boto3.client(
    "s3",
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)

# Configuration
LOCAL_FOLDER = "../ecommerce_lab5/Data"
print(f"Looking for files in: {os.path.abspath(LOCAL_FOLDER)}")

S3_BUCKET = os.getenv("BUCKET_NAME")
print(S3_BUCKET)
# Define the nested folder prefix in S3
S3_FOLDER_PREFIX = "ecommerce_data/"

def upload_files_to_s3(local_folder, bucket):
    for root, _, files in os.walk(local_folder):
        print(f"Checking folder: {root}")
        for file in files:
            local_path = os.path.join(root, file)
            s3_key = os.path.relpath(local_path, local_folder)  # Preserve folder structure
            
            # Add the nested folder prefix to the S3 key
            s3_key = os.path.join(S3_FOLDER_PREFIX, s3_key).replace("\\", "/")  # Ensure correct path separators
            
            try:
                s3.upload_file(local_path, bucket, s3_key)
                print(f"Uploaded: {file} to s3://{bucket}/{s3_key}")
            except Exception as e:
                print(f"Failed to upload {file}: {e}")

# Run the upload
print("Calling upload_files_to_s3...")
upload_files_to_s3(LOCAL_FOLDER, S3_BUCKET)