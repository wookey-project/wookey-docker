# Wookey build system
#
# VERSION               0.1
# DOCKER-VERSION        0.2

from	debian:buster as wookey_builder

# make sure the package repository is up to date
run echo "deb http://deb.debian.org/debian/ buster contrib non-free" >> /etc/apt/sources.list
run	apt-get update

# debian packages dependencies
run	apt-get install -y bash repo git make gcc-arm-none-eabi binutils-arm-none-eabi python-pip python3-pip python-pyscard python-crypto openjdk-11-jdk maven ant curl zip unzip bash kconfig-frontends

# python dependencies (out of debian)
run pip install intelhex

# installing Ada toolchain
run curl -o /tmp/gnat-community-2019-20190517-arm-elf-linux64-bin http://mirrors.cdn.adacore.com/art/5ce0010709dcd015aaf8262b
run echo "6696259f92b40178ab1cc1d3e005acf705dc4162  /tmp/gnat-community-2019-20190517-arm-elf-linux64-bin" > /tmp/gnat.sha1sum
run sha1sum -c /tmp/gnat.sha1sum

run chmod +x /tmp/gnat-community-2019-20190517-arm-elf-linux64-bin

run git clone https://github.com/AdaCore/gnat_community_install_script.git /tmp/gnat_install
run /tmp/gnat_install/install_package.sh /tmp/gnat-community-2019-20190517-arm-elf-linux64-bin /opt/adacore-arm-eabi

# installing Javacard SDK
run git clone https://github.com/martinpaljak/oracle_javacard_sdks.git /tmp/oracle_sdks

run groupadd build
run useradd -d /build -ms /bin/bash -g build build;

user build:build
workdir /build

run echo "export PATH=/opt/adacore-arm-eabi/bin:/usr/local/bin:$PATH" > /build/.bashrc;
# now install and set the SDK
run /bin/dash -c 'cd /build; \
                  git config --global color.ui true; \
                  /usr/bin/repo init -u https://github.com/wookey-project/manifest.git -m wookey.xml; \
                  /usr/bin/repo sync'

# local config, corresponding to the local toolchains installation paths
run cd /build; echo 'export CROSS_COMPILE=arm-none-eabi-' > setenv.local.sh; echo 'export JAVA_SC_SDK=/tmp/oracle_sdks/jc303_kit' >> setenv.local.sh

from wookey_builder as wookey_debugger

user root
workdir /tmp

# add debug and flash specific content
run apt-get install -y gdb-multiarch openocd

user build:build
workdir /build

cmd ["/bin/bash"] 
