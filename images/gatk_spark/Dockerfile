FROM ubuntu:22.04
LABEL author="oklimchuk@biotc.ru"

# https://www.oracle.com/java/technologies/downloads/
ARG JAVA_VERSION="8"
# https://github.com/broadinstitute/gatk
ARG GATK_VERSION="4.3.0.0"
# https://github.com/apache/spark
ARG SPARK_VERSION="3.2.3"

ARG DEBIAN_FRONTEND="noninteractive"

# apt-packages
# "apt-get install --no-install-recommends" is not allowed because python3 fails otherwise
RUN apt-get update -y                                                         \
    && apt-get upgrade -y                                                     \
    && apt-get install --upgrade -y                                           \
    openjdk-${JAVA_VERSION}-jdk-headless openjdk-${JAVA_VERSION}-jre-headless \
    wget                                                                      \
    zip                                                                       \
    && apt-get autoremove --purge                                             \
    && apt-get clean                                                          \
    && rm -rf /var/lib/apt/lists/*

# GATK
RUN wget -q https://github.com/broadinstitute/gatk/releases/download/${GATK_VERSION}/gatk-${GATK_VERSION}.zip \
    && unzip -q gatk-${GATK_VERSION}.zip && rm gatk-${GATK_VERSION}.zip \
    && cp gatk-${GATK_VERSION}/gatk-package-${GATK_VERSION}-local.jar /opt/gatk.jar \
    && rm -r gatk-${GATK_VERSION}

# Apache Spark
RUN wget -q https://github.com/apache/spark/archive/refs/tags/v${SPARK_VERSION}.tar.gz \
    && tar -xzf v${SPARK_VERSION}.tar.gz && rm v${SPARK_VERSION}.tar.gz \
    && cd spark-${SPARK_VERSION} && ./build/mvn -DskipTests clean package && cd .. \
    && rm -r spark-${SPARK_VERSION}
