FROM base:0.3
LABEL author="oklimchuk@biotc.ru"

# https://github.com/samtools/samtools
ARG SAMTOOLS_VERSION="1.16.1"
# https://github.com/samtools/bcftools
ARG BCFTOOLS_VERSION="1.16"
# https://github.com/samtools/htslib
ARG HTSLIB_VERSION="1.16"
# https://github.com/arq5x/bedtools2
ARG BEDTOOLS_VERSION="2.30.0"

### "SAMtools suite" ###
# samtools
RUN wget -q https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && tar -xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 && rm samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && cd samtools-${SAMTOOLS_VERSION} && ./configure && make && make install && cd .. \
    && rm -r samtools-${SAMTOOLS_VERSION}
# bcftools
RUN wget -q https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2 \
    && tar -xjf bcftools-${BCFTOOLS_VERSION}.tar.bz2 && rm bcftools-${BCFTOOLS_VERSION}.tar.bz2 \
    && cd bcftools-${BCFTOOLS_VERSION} && ./configure && make && make install && cd .. \
    && rm -r bcftools-${BCFTOOLS_VERSION}
# htslib: bgzip, tabix, etc.
RUN wget -q https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 \
    && tar -xjf htslib-${HTSLIB_VERSION}.tar.bz2 && rm htslib-${HTSLIB_VERSION}.tar.bz2 \
    && cd htslib-${HTSLIB_VERSION} && ./configure && make && make install && cd .. \
    && rm -r htslib-${HTSLIB_VERSION}

# bedtools
RUN wget -q https://github.com/arq5x/bedtools2/releases/download/v${BEDTOOLS_VERSION}/bedtools-${BEDTOOLS_VERSION}.tar.gz \
    && tar -xzf bedtools-${BEDTOOLS_VERSION}.tar.gz && rm bedtools-${BEDTOOLS_VERSION}.tar.gz \
    && cd bedtools2 && sed -i 's/python/python3/g' Makefile && make && make install && cd .. \
    && rm -r bedtools2
