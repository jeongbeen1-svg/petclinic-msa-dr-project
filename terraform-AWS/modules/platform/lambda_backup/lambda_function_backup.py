import boto3
import json
import pymysql
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# 데이터가 있는 경우에만 s3에 업로드됩니다
def lambda_handler(event, context):
    conn = None
    all_backup_data = {}
    total_rows = 0

    try:
        logger.info('Lambda 시작: RDS 연결 시도')
        conn = pymysql.connect(
            host=os.environ['RDS_ENDPOINT'],
            user=os.environ['RDS_USER'],
            password=os.environ['RDS_PASSWORD'],
            database=os.environ['RDS_DATABASE'],
            port=int(os.environ.get('RDS_PORT', '3306')),
            connect_timeout=5,
            read_timeout=10,
            write_timeout=10
        )

        logger.info('RDS 연결 성공')

        with conn.cursor() as cursor:
            # 모든 테이블 목록 가져오기
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]
            logger.info(f'조회된 테이블 목록: {tables}')

            # 각 테이블별로 데이터 조회
            for table in tables:
                cursor.execute(f"SELECT * FROM `{table}`")
                # 컬럼 이름 추출
                columns = [desc[0] for desc in cursor.description]

                # 데이터를 컬럼명과 매핑 (List of Dicts)
                data = [dict(zip(columns, row)) for row in cursor.fetchall()]

                # 테이블별 스키마와 데이터 분리 저장
                all_backup_data[table] = {
                    "schema": columns,
                    "rows": data
                }
                total_rows += len(data)

                logger.info(f'테이블 {table} 조회 완료, row_count={len(data)}')

        s3 = boto3.client('s3')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        key = f"rds-backup/backup_{timestamp}.json"

        s3.put_object(
            Bucket=os.environ['S3_BUCKET'],
            Key=key,
            Body=json.dumps(all_backup_data, default=str)
        )

        logger.info(f'S3 업로드 완료: bucket={os.environ["S3_BUCKET"]}, key={key}')
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Success',
                'row_count': total_rows,
                'tables_backed_up': tables,
                's3_key': key
            })
        }
    except Exception as e:
        logger.exception('Lambda 처리 중 예외 발생')
        return {'statusCode': 500, 'body': json.dumps(str(e))}
    finally:
        if conn:
            conn.close()
            logger.info('RDS 연결 종료')
