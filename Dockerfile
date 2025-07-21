FROM debian:bookworm-slim AS builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates wget

ENV BITCOIN_VERSION=29.0
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz \
	BITCOIN_SHA256=a681e4f6ce524c338a105f214613605bac6c33d58c31dc5135bbc02bc458bb6c

RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt


FROM debian:bookworm-slim
COPY --from=builder /usr/local/bin/bitcoind /usr/local/bin/bitcoin-cli /usr/local/bin/
RUN groupadd -g 1234 -r bitcoin && useradd -u 1234 -r -m -g bitcoin bitcoin \
	&& ln -s /usr/local/bin/bitcoin-cli /usr/local/bin/c

ENV BITCOIN_DATA=/data

# create data directory
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh

USER bitcoin

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
