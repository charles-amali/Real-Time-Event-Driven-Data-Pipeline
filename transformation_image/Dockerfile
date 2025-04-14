# Base image
FROM python:3.9-slim

# Set environment variables
ENV SPARK_VERSION=3.3.2
ENV HADOOP_VERSION=3
ENV PYSPARK_PYTHON=python3
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$JAVA_HOME/bin:$PATH
ENV PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.9.5-src.zip
ENV HADOOP_AWS_VERSION=3.3.1
ENV AWS_SDK_VERSION=1.11.901

# Install Java and required tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jdk wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Spark
RUN wget --no-verbose https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz && \
    tar -xvzf spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz && \
    mv spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION $SPARK_HOME && \
    rm spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz

# Install AWS JARs for S3
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar -P $SPARK_HOME/jars/ && \
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar -P $SPARK_HOME/jars/

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install PySpark explicitly
RUN pip install pyspark

# Set working directory
WORKDIR /app

# Copy application code
COPY . .



# For Dockerfile.kpi_computation:
CMD ["spark-submit", "transform_kpi.py"]