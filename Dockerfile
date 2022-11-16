FROM ubuntu:latest

ENV SCRIPT_EXPORTER_VERSION=v2.5.2

RUN apt-get update -qq && apt-get upgrade -y -qq && apt-get install curl -y -qq

RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
RUN apt-get install speedtest -y -qq

RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) _arch=amd64 ;; \
      armhf) _arch=armv7 ;; \
      aarch64) _arch=arm64 ;; \
      *) _arch="$ARCH" ;; \
    esac && \
    echo https://github.com/ricoberger/script_exporter/releases/download/${SCRIPT_EXPORTER_VERSION}/script_exporter-linux-${_arch} && \
    curl -kfsSL -o /usr/local/bin/script_exporter \
      https://github.com/ricoberger/script_exporter/releases/download/${SCRIPT_EXPORTER_VERSION}/script_exporter-linux-${_arch} && \
    chmod +x /usr/local/bin/script_exporter

COPY config.yaml config.yaml
COPY entrypoint.sh entrypoint.sh
COPY speedtest-exporter.sh /usr/local/bin/speedtest-exporter.sh

EXPOSE 9469

ENTRYPOINT  [ "/entrypoint.sh" ]
