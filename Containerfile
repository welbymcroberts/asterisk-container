FROM docker.io/library/ubuntu:24.04 as build
LABEL maintainer="Welby McRoberts <containers@whmcr.com>"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get full-upgrade --yes 
RUN apt-get install --yes -qq --no-install-recommends --no-install-suggests \
  build-essential pkg-config autoconf-archive \
  libedit-dev libjansson-dev libsqlite3-dev uuid-dev libxml2-dev \
  libspeex-dev libspeexdsp-dev libogg-dev libvorbis-dev libasound2-dev portaudio19-dev libcurl4-openssl-dev xmlstarlet bison flex \
  libpq-dev unixodbc-dev libneon27-dev libgmime-3.0-dev liblua5.2-dev liburiparser-dev libxslt1-dev libssl-dev \
  libmysqlclient-dev libbluetooth-dev libradcli-dev freetds-dev libjack-jackd2-dev bash libcap-dev \
  libsnmp-dev libiksemel-dev libcorosync-common-dev libcpg-dev libcfg-dev libnewt-dev libpopt-dev libical-dev libspandsp-dev \
  libresample1-dev libc-client2007e-dev binutils-dev libsrtp2-dev libgsm1-dev doxygen graphviz zlib1g-dev libldap2-dev \
  libcodec2-dev libfftw3-dev libsndfile1-dev libunbound-dev libjwt-dev \
  wget subversion curl \
  bzip2 patch \
  ca-certificates
WORKDIR /usr/src/
RUN curl -LO https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz && tar xvf asterisk-22-current.tar.gz
WORKDIR /usr/src//asterisk-22.5.2/
RUN svn export https://svn.digium.com/svn/thirdparty/mp3/trunk addons/mp3 $@
RUN sed -i -e '/#include "asterisk.h"/i#define ASTMM_LIBC ASTMM_REDIRECT' \
        addons/mp3/interface.c
RUN ./configure --prefix=/asterisk
RUN make menuselect.makeopts
RUN menuselect/menuselect --disable CORE-SOUNDS-EN-GSM menuselect.makeopts && \
menuselect/menuselect --disable MOH-OPSOUND-WAV menuselect.makeopts && \
menuselect/menuselect --enable chan_ooh323 menuselect.makeopts && \
menuselect/menuselect --enable format_mp3 menuselect.makeopts && \
menuselect/menuselect --enable app_statsd menuselect.makeopts && \
menuselect/menuselect --enable app_voicemail_imap menuselect.makeopts && \
menuselect/menuselect --enable app_voicemail_odbc menuselect.makeopts && \
menuselect/menuselect --enable codec_opus menuselect.makeopts && \
menuselect/menuselect --enable codec_silk menuselect.makeopts && \
menuselect/menuselect --enable codec_siren7 menuselect.makeopts && \
menuselect/menuselect --enable codec_siren14 menuselect.makeopts && \
menuselect/menuselect --enable RADIO_RELAX menuselect.makeopts
RUN make -j $(( $(nproc) + $(nproc) / 2 )) all
RUN make install
RUN make basic-pbx



FROM docker.io/library/ubuntu:24.04
COPY --from=build /asterisk /asterisk
RUN apt-get update && apt-get full-upgrade --yes && apt-get install --yes -qq --no-install-recommends --no-install-suggests \
  pkg-config \
  libedit2 libjansson4 libsqlite3-0 uuid libxml2 \
  libspeex1 libspeexdsp1 libogg0 libvorbis0a libasound2t64 libcurl4t64 xmlstarlet \
  libpq5 unixodbc libneon27t64 libgmime-3.0-0t64 liblua5.2-0 liburiparser1 libxslt1.1 libssl3t64 \
  libmysqlclient21 libradcli4 libjack-jackd2-0 bash \
  libsnmp40t64 libiksemel3 libcpg4 libcfg7 libnewt0.52 libpopt0 libical3t64 libspandsp2t64 \
  libresample1 libc-client2007e binutils libsrtp2-1 libgsm1 zlib1g libldap2 \
  libcodec2-1.2 libfftw3-bin libsndfile1 libunbound8 libjwt2 \
  wget curl \
  bzip2 \
  ca-certificates

CMD /asterisk/sbin/asterisk -vvvgf
