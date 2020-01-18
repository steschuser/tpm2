FROM ubuntu:eoan
# Change these for different version
ARG simulator_url="https://downloads.sourceforge.net/project/ibmswtpm2/"
#ARG simulator_file="ibmtpm1563.tar.gz"
#ARG simulator_file="ibmtpm974.tar.gz"
#ARG simulator_file="ibmtpm1332.tar.gz"
ARG simulator_file="ibmtpm1119.tar.gz"
ARG tls_version="libcurl4-gnutls-dev"

# Setup OS
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget build-essential libssl-dev iproute2 git autoconf automake autoconf-archive m4 libtool pkg-config libjson-c-dev ${tls_version} doxygen libdbus-1-dev libglib2.0-dev dbus-x11 p11-kit python3 libsqlite3-dev libyaml-dev python3-pyasn1-modules python3-yaml python3-cryptography libp11-kit-dev opensc gnutls-bin

# Dont have any packages yet, build locally
# install TSS itself
RUN cd /opt && git clone https://github.com/tpm2-software/tpm2-tss.git
RUN cd /opt/tpm2-tss &&  ./bootstrap && ./configure --prefix=/usr && make &&  make install
RUN ldconfig

RUN cd /opt &&  git clone https://github.com/tpm2-software/tpm2-abrmd.git
RUN cd /opt/tpm2-abrmd && ./bootstrap && ./configure --with-dbuspolicydir=/etc/dbus-1/system.d --with-systemdsystemunitdir=/usr/lib/systemd/system --libdir=/usr/lib64 --prefix=/usr && make && make install
RUN ldconfig

# Install tools itself
RUN cd /opt && git clone https://github.com/tpm2-software/tpm2-tools.git
RUN cd /opt/tpm2-tools && ./bootstrap && ./configure --prefix=/usr && make && make install
RUN ldconfig

# Install pcks11 support
RUN cd /opt && git clone https://github.com/tpm2-software/tpm2-pkcs11.git
RUN cd /opt/tpm2-pkcs11 && ./bootstrap && ./configure --prefix=/usr && make && make install
RUN ldconfig

# Install tpm2-tss-engine
RUN cd /opt && git clone https://github.com/tpm2-software/tpm2-tss-engine.git
RUN cd /opt/tpm2-tss-engine && ./bootstrap && ./configure --prefix=/usr && make && make install
RUN ldconfig


# Build Simulator
RUN echo ${simulator_url}${simulator_file} &&  mkdir /opt/tpm2simulator && wget ${simulator_url}${simulator_file} -O /opt/tpm2simulator/${simulator_file}
WORKDIR /opt/tpm2simulator
RUN tar xzf ${simulator_file} && rm ${simulator_file} && mkdir run && mkdir log
RUN cd src && make


RUN ldconfig

# Copy our scrips
COPY scripts /root/scripts
# Copy our entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
WORKDIR /root
# Start all the things
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
