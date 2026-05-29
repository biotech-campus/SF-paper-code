FROM mgi:0.3
LABEL author="oklimchuk@biotc.ru,dpustoshilov@biotc.ru"

ARG VERSION="2.1"

COPY trim_map.sh /opt/
RUN chmod +x /opt/trim_map.sh

ENTRYPOINT ["bash", "/opt/trim_map.sh"]
