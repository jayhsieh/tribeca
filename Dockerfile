FROM node:5
RUN apt-get update

RUN apt-get install -y git
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		numactl \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

# gpg: key 7F0CEB10: public key "Richard Kreuter <richard@10gen.com>" imported
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10

ENV MONGO_MAJOR 3.0
ENV MONGO_VERSION 3.0.14
ENV MONGO_PACKAGE mongodb-org

RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		${MONGO_PACKAGE}=$MONGO_VERSION \
		${MONGO_PACKAGE}-server=$MONGO_VERSION \
		${MONGO_PACKAGE}-shell=$MONGO_VERSION \
		${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb
EXPOSE 27017
CMD ["mongod"]
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		numactl \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/contino/tribeca.git

WORKDIR tribeca

# Chose the branch you want to build. Leave as it is if you want to build the master branch (recommanded).
# RUN git checkout -B YOUR-NAME-OF-THE-BRANCH --track remotes/origin/NAME-OF-THE-BRANCH-IN-GITHUB

RUN npm install -g grunt-cli typings@0.8.1 forever
RUN npm install
RUN typings install
RUN grunt compile

EXPOSE 3000 5000

# General config properties. Properties with `NULL` should be replaced with your own exchange account information.
ENV TRIBECA_MODE dev
ENV EXCHANGE null
ENV TradedPair BTC/USD
ENV WebClientUsername NULL
ENV WebClientPassword NULL
ENV WebClientListenPort 3000
# IP to access mongo instance. If you are on a mac, run `boot2docker ip` and replace `tribeca-mongo`.
ENV MongoDbUrl mongodb://localhost:27017/tribeca

# DEV
## HitBtc
ENV HitBtcPullUrl http://demo-api.hitbtc.com
ENV HitBtcOrderEntryUrl ws://demo-api.hitbtc.com:8080
ENV HitBtcMarketDataUrl ws://demo-api.hitbtc.com:80
ENV HitBtcSocketIoUrl https://demo-api.hitbtc.com:8081
ENV HitBtcApiKey NULL
ENV HitBtcSecret NULL
ENV HitBtcOrderDestination HitBtc
## Coinbase
## Use GDAX keys
ENV CoinbaseRestUrl https://api-public.sandbox.gdax.com
ENV CoinbaseWebsocketUrl wss://ws-feed-public.sandbox.gdax.com
ENV CoinbasePassphrase NULL
ENV CoinbaseApiKey NULL
ENV CoinbaseSecret NULL
ENV CoinbaseOrderDestination Coinbase
## OkCoin
ENV OkCoinWsUrl wss://real.okcoin.com:10440/websocket/okcoinapi
ENV OkCoinHttpUrl https://www.okcoin.com/api/v1/
ENV OkCoinApiKey NULL
ENV OkCoinSecretKey NULL
ENV OkCoinOrderDestination OkCoin
## Bitfinex
ENV BitfinexHttpUrl https://api.bitfinex.com/v1
ENV BitfinexKey NULL
ENV BitfinexSecret NULL
ENV BitfinexOrderDestination Bitfinex

# PROD - values provided for reference.
## HitBtc
#ENV HitBtcPullUrl http://api.hitbtc.com
#ENV HitBtcOrderEntryUrl wss://api.hitbtc.com:8080
#ENV HitBtcMarketDataUrl ws://api.hitbtc.com:80
#ENV HitBtcSocketIoUrl https://api.hitbtc.com:8081
## Coinbase
#ENV CoinbaseRestUrl https://api.gdax.com
#ENV CoinbaseWebsocketUrl wss://ws-feed.gdax.com

WORKDIR tribeca/service
CMD ["forever", "main.js"]
