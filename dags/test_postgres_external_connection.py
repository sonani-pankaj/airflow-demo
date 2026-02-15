"""
DAG to test connection with external PostgreSQL database.
This DAG verifies the postgres_external connection is working properly.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.standard.operators.python import PythonOperator
from airflow.hooks.base import BaseHook


# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}


def print_connection_info():
    """Print connection details for verification."""
    try:
        conn = BaseHook.get_connection('postgres_external_docker')
        print(f"Connection ID: {conn.conn_id}")
        print(f"Host: {conn.host}")
        print(f"Port: {conn.port}")
        print(f"Schema/Database: {conn.schema}")
        print(f"Login: {conn.login}")
        print("Connection retrieved successfully! Pankaj")
    except Exception as e:
        print(f"Error getting connection: {e}")
        raise


def test_connection_with_hook():
    """Test the connection using psycopg2 directly."""
    import psycopg2
    
    conn_config = BaseHook.get_connection('postgres_external_docker')
    
    # Create actual database connection
    connection = psycopg2.connect(
        host=conn_config.host,
        port=conn_config.port or 5432,
        database=conn_config.schema,
        user=conn_config.login,
        password=conn_config.password
    )
    
    cursor = connection.cursor()
    
    # Get PostgreSQL version
    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]
    print(f"PostgreSQL Version: {version}")
    
    # Get current database
    cursor.execute("SELECT current_database();")
    db_name = cursor.fetchone()[0]
    print(f"Connected to database: {db_name}")
    
    # Get current user
    cursor.execute("SELECT current_user;")
    user = cursor.fetchone()[0]
    print(f"Connected as user: {user}")
    
    # List all tables (if any)
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    tables = cursor.fetchall()
    print(f"Tables in public schema: {[t[0] for t in tables] if tables else 'No tables yet'}")
    
    cursor.close()
    connection.close()
    
    print("Connection test completed successfully!")

with DAG(
    dag_id='test_postgres_external_connection',
    default_args=default_args,
    description='Test connection to external PostgreSQL database',
    schedule=None,  # Manual trigger only
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['test', 'postgres', 'connection'],
) as dag:

    # Task 1: Print connection info
    task_print_connection = PythonOperator(
        task_id='print_connection_info',
        python_callable=print_connection_info,
    )

    # Task 2: Test connection using PostgresHook
    task_test_hook = PythonOperator(
        task_id='test_connection_with_hook',
        python_callable=test_connection_with_hook,
    )

    # Task 3: Create a test table
    task_create_table = SQLExecuteQueryOperator(
        task_id='create_test_table',
        conn_id='postgres_external',
        sql="""
            CREATE TABLE IF NOT EXISTS connection_test (
                id SERIAL PRIMARY KEY,
                test_name VARCHAR(100),
                test_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(50)
            );
        """,
    )

    # Task 4: Insert test data
    task_insert_data = SQLExecuteQueryOperator(
        task_id='insert_test_data',
        conn_id='postgres_external',
        sql="""
            INSERT INTO connection_test (test_name, status)
            VALUES ('Airflow Connection Test', 'SUCCESS');
        """,
    )

    # Task 5: Query and verify data
    task_query_data = SQLExecuteQueryOperator(
        task_id='query_test_data',
        conn_id='postgres_external',
        sql="""
            SELECT * FROM connection_test ORDER BY test_timestamp DESC LIMIT 5;
        """,
        do_xcom_push=True,  # Push results to XCom so they can be accessed from browse Xcom tab
    )    

    # Task 6: Clean up (optional - drop test table)
    task_cleanup = SQLExecuteQueryOperator(
        task_id='cleanup_test_table',
        conn_id='postgres_external',
        sql="""
            -- Uncomment below to drop the test table after testing
            -- DROP TABLE IF EXISTS connection_test;
            SELECT 'Cleanup task completed (table preserved for inspection)' as message;
        """,
    )

    # Define task dependencies
    task_print_connection >> task_test_hook >> task_create_table >> task_insert_data >> task_query_data >> task_cleanup
