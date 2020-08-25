FROM httpd as build
ARG MOD_OPENIDC_VERSION=v2.4.3
WORKDIR /work
RUN apt-get -qq update \
 && apt-get -qq install --no-install-recommends -y ca-certificates gcc apache2-dev libcjose-dev curl libssl-dev libjansson-dev libcurl4-openssl-dev libpcre3-dev pkg-config make libhiredis-dev \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sL https://github.com/zmartzone/mod_auth_openidc/archive/$MOD_OPENIDC_VERSION.tar.gz > src.tar.gz \
 && tar zxf src.tar.gz \
 && cd /work/mod_auth_openidc-* \
 && ./autogen.sh \
 && ./configure --with-apxs2=/usr/local/apache2/bin/apxs \
 && make \
 && make install

FROM httpd as test
COPY --from=build /usr/local/apache2/modules/mod_auth_openidc.so /usr/local/apache2/modules/mod_auth_openidc.so
RUN apt-get -qq update \
 && apt-get -qq install --no-install-recommends -y ca-certificates libcjose0 libhiredis0.14 curl \
 && rm -rf /var/lib/apt/lists/*
RUN echo Include /usr/local/apache2/conf/extras/mod_auth_openidc.conf >> /usr/local/apache2/conf/httpd.conf
COPY mod_auth_openidc.conf /usr/local/apache2/conf/extras/mod_auth_openidc.conf
RUN httpd -k start && curl -s http://localhost/secure

FROM httpd
COPY --from=build /usr/local/apache2/modules/mod_auth_openidc.so /usr/local/apache2/modules/mod_auth_openidc.so
RUN apt-get -qq update \
 && apt-get -qq install --no-install-recommends -y ca-certificates libcjose0 libhiredis0.14 curl \
 && rm -rf /var/lib/apt/lists/*
