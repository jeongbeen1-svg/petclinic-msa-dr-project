import os
import boto3
from azure.storage.blob import BlobServiceClient

def lambda_handler(event, context):
    # 1. 트리거된 S3 이벤트에서 파일 정보 추출
    s3_event = event['Records'][0]['s3']
    bucket_name = s3_event['bucket']['name']
    key = s3_event['object']['key']

    # 2. S3에서 파일 읽기
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=bucket_name, Key=key)
    file_content = response['Body'].read()

    # 3. Azure로 전송
    # 환경변수 AZURE_CONNECTION_STRING 설정 필요
    connect_str = os.environ['AZURE_CONNECTION_STRING']
    blob_service_client = BlobServiceClient.from_connection_string(connect_str)
    
    # 컨테이너 이름 지정
    blob_client = blob_service_client.get_blob_client(container="backup-by-aws", blob=key)
    blob_client.upload_blob(file_content, overwrite=True)

    print(f"Azure 전송 완료: {key}")
    return {"status": "success", "file": key}