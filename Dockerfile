FROM apache/airflow:3.1.6

# Install airflow-code-editor plugin
USER root
COPY requirements.txt /requirements.txt
USER airflow
RUN pip install --no-cache-dir -r /requirements.txt
