import psycopg2
import os

def get_connection():
    return psycopg2.connect(
        host = os.getenv("DB_HOST","postgres"),
        port = os.getenv("DB_PORT",5432),
        database = os.getenv("DB_NAME","dw"),
        user=os.getenv("DB_USER","postgres"),
        password=os.getenv("DB_PASSWORD","local_1234")
    )