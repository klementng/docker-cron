FROM docker.io/ubuntu:jammy

ENV PUID=1000
ENV PGID=1000
ENV EXTRA_PACKAGES=""
ENV TZ=UTC

RUN apt update && \
    apt install -y --no-install-recommends cron ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
