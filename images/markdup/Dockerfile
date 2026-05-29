FROM gatk-spark:0.3
LABEL author="oklimchuk@biotc.ru"

COPY markdup.sh /opt/
RUN chmod +x /opt/markdup.sh

ENTRYPOINT ["bash", "/opt/markdup.sh"]
