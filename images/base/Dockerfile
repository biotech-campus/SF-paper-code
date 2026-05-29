FROM ubuntu:22.04
LABEL author="oklimchuk@biotc.ru"

# https://www.oracle.com/java/technologies/downloads/
ARG JAVA_VERSION="17"
# https://www.python.org/downloads/
ARG PYTHON3_VERSION="3.11"
# https://github.com/pypa/pip
ARG PIP3_VERSION="22.3.1"
# https://cloud.google.com/sdk/docs/downloads-versioned-archives
ARG GCLOUD_VERSION="412.0.0"
# https://github.com/snakemake/snakemake
ARG SNAKEMAKE_VERSION="7.19.1"
# https://cran.r-project.org/src/base
ARG R_VERSION="4.2.2"
# https://www.bioconductor.org/packages/release/bioc/html/BiocVersion.html
ARG BIOCMANAGER_VERSION="3.16"

ARG DEBIAN_FRONTEND="noninteractive"

# apt-packages
# "apt-get install --no-install-recommends" is not allowed because python3 fails otherwise
RUN apt-get update -y                                                         \
    && apt-get upgrade -y                                                     \
    && apt-get install --upgrade -y                                           \
    bc                                     `# interactive algebraic language` \
    openjdk-${JAVA_VERSION}-jdk-headless openjdk-${JAVA_VERSION}-jre-headless \
    parallel                                                                  \
    pigz                                                                      \
    python${PYTHON3_VERSION}                                                  \
    python3-pip                                                               \
    wget                                                                      \
    zip                                                                       \
    build-essential                                           `# компиляторы` \
    gfortran                                                        `# для R` \
    libcurl4-openssl-dev                                            `# для R` \
    libpcre2-dev                                                    `# для R` \
    libreadline-dev                                                 `# для R` \
    libbz2-dev               `# для R, samtools, bcftools, htslib и bedtools` \
    liblzma-dev              `# для R, samtools, bcftools, htslib и bedtools` \
    libdeflate-dev                                              `# для fastp` \
    libisal-dev                                                 `# для fastp` \
    && apt-get autoremove --purge                                             \
    && apt-get clean                                                          \
    && rm -rf /var/lib/apt/lists/*

# python3-libraries
RUN python3 -m pip install --upgrade pip==${PIP3_VERSION} \
    && pip3 install --upgrade --no-cache-dir              \
    biopython                                             \
    Cython                              `# для snakemake` \
    graphviz                                              \
    matplotlib                                            \
    numpy                                                 \
    pandas                                                \
    scikit-learn                                          \
    scipy                                                 \
    seaborn

# google-cloud-sdk
RUN wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    && tar -xzf google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz && rm google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    && mv google-cloud-sdk /opt/ && bash /opt/google-cloud-sdk/install.sh --quiet --usage-reporting false \
    && ln -sf /opt/google-cloud-sdk/bin/gcloud /usr/bin/gcloud \
    && ln -sf /opt/google-cloud-sdk/bin/gsutil /usr/bin/gsutil

# snakemake
RUN wget -q https://github.com/snakemake/snakemake/archive/v${SNAKEMAKE_VERSION}.tar.gz \
    && tar -xzf v${SNAKEMAKE_VERSION}.tar.gz && rm v${SNAKEMAKE_VERSION}.tar.gz \
    && cd snakemake-${SNAKEMAKE_VERSION} && python3 setup.py build && python3 setup.py install && cd .. \
    && rm -r snakemake-${SNAKEMAKE_VERSION}

# R
RUN wget -q https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz \
    && tar -xzf R-${R_VERSION}.tar.gz && rm R-${R_VERSION}.tar.gz \
    && cd R-${R_VERSION} && ./configure --with-x=no && make && make install && cd .. \
    && rm -r R-${R_VERSION}

# BiocManager
RUN Rscript -e "install.packages('BiocManager', repos='https://cran.r-project.org')" \
    && Rscript -e "BiocManager::install(version=${BIOCMANAGER_VERSION}, ask=FALSE)"
