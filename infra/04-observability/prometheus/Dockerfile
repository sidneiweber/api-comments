FROM quay.io/prometheus/prometheus:v2.45.3
ADD prometheus.yml /etc/prometheus/

ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--web.enable-lifecycle", \
             "--web.enable-admin-api", \
             "--web.external-url=https://prometheus.sidneiweber.com.br", \
             "--storage.tsdb.min-block-duration=1h", \
             "--storage.tsdb.retention.time=1h", \
             "--storage.tsdb.wal-compression", \
             "--storage.tsdb.max-block-duration=1h" ]