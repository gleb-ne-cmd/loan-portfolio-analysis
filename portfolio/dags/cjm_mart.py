from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from functions import execute_sql_script

OWNER = ""

with DAG(
          dag_id=f'cjm_mart_dag_{OWNER}',
          start_date = datetime(2026, 5, 4),
          schedule = '0 9,15 * * *',
          catchup=False,
          tags=[OWNER],
          default_args = {
                    "owner": OWNER
          }
) as dag:
          cjm_auth = PythonOperator(
                  task_id = 'auth',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_auth'}
          )
          cjm_reg = PythonOperator(
                  task_id = 'registration',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_reg'}
          )
          cjm_del = PythonOperator(
                  task_id = 'delete',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_del'}
          )
          cjm_orders = PythonOperator(
                  task_id = 'orders',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_orders'}
          )
          cjm_crm_sms = PythonOperator(
                  task_id = 'crm_sms',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_crm_sms'}
          )
          cjm_crm_email = PythonOperator(
                  task_id = 'crm_email',
                  python_callable=execute_sql_script,
                  op_kwargs={'file_path': f'/opt/airflow/dags/{OWNER}/sql/cjm/cjm_mart_crm_email'}
          )
