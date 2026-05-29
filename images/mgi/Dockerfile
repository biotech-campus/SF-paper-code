FROM bioinformatics:0.3
LABEL author="oklimchuk@biotc.ru"

# https://github.com/marcelm/cutadapt
ARG CUTADAPT_VERSION="4.2"
# https://github.com/OpenGene/fastp
ARG FASTP_VERSION="0.23.2"
## https://github.com/lh3/bwa
#ARG BWA_VERSION="0.7.17"
# https://github.com/broadinstitute/gatk
ARG GATK_VERSION="4.3.0.0"

# cutadapt
RUN pip3 install --upgrade --no-cache-dir \
    cutadapt==${CUTADAPT_VERSION}

# fastp
RUN wget -q https://github.com/OpenGene/fastp/archive/refs/tags/v${FASTP_VERSION}.tar.gz \
    && tar -xzf v${FASTP_VERSION}.tar.gz && rm v${FASTP_VERSION}.tar.gz \
    && cd fastp-${FASTP_VERSION} && make && make install && cd .. \
    && rm -r fastp-${FASTP_VERSION}

# bwa
RUN apt-get update -y                                             \
    && apt-get upgrade -y                                         \
    && apt-get install --upgrade -y                               \
    bwa                                                           \
    && apt-get autoremove --purge                                 \
    && apt-get clean                                              \
    && rm -rf /var/lib/apt/lists/*

# GATK
RUN wget -q https://github.com/broadinstitute/gatk/releases/download/${GATK_VERSION}/gatk-${GATK_VERSION}.zip \
    && unzip -q gatk-${GATK_VERSION}.zip && rm gatk-${GATK_VERSION}.zip \
    && cp gatk-${GATK_VERSION}/gatk-package-${GATK_VERSION}-local.jar /opt/gatk.jar \
    && rm -r gatk-${GATK_VERSION}
