# Wookey build system
#
# VERSION               0.1
# DOCKER-VERSION        0.2

from	debian:buster as wookey_builder

# make sure the package repository is up to date
run echo "deb http://deb.debian.org/debian/ buster contrib non-free" >> /etc/apt/sources.list
run	apt-get update

# debian packages dependencies
run	apt-get install -y bash repo sudo git make python-pip python3-pip python-pyscard python-crypto openjdk-11-jdk maven ant curl zip unzip bash kconfig-frontends bzip2 vim emacs-nox python-sphinx imagemagick python-docutils texlive-pictures texlive-latex-extra texlive-fonts-recommended latexmk ghostscript coreutils fdisk wget

# python dependencies (out of debian)
run pip install intelhex

# installing Ada toolchain
run wget -O /tmp/gnat-community-2018-20180524-arm-elf-linux64-bin https://community.download.adacore.com/v1/6696259f92b40178ab1cc1d3e005acf705dc4162?filename=gnat-community-2019-20190517-arm-elf-linux64-bin
run echo "6696259f92b40178ab1cc1d3e005acf705dc4162  /tmp/gnat-community-2018-20180524-arm-elf-linux64-bin" > /tmp/gnat.sha1sum
run sha1sum -c /tmp/gnat.sha1sum

# installing ARM toolchain. The default Debian Buster toolchain can also be used (gcc 7.3), yet the gcc-7 and compiler is more conservative in its
# optimizations, reducing the performances of the AES algorithm at optimization compile time
run curl -o  /tmp/gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2 https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6-2017q2/gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2
run echo "0f245753715e5dc8b513c281a0f6dfaed371ad5c  /tmp/gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2" > /tmp/gcc.sha1sum
run sha1sum -c /tmp/gcc.sha1sum
run tar -xf /tmp/gcc-arm-none-eabi-6-2017-q2-update-linux.tar.bz2 -C /opt


run chmod +x /tmp/gnat-community-2018-20180524-arm-elf-linux64-bin

run git clone https://github.com/AdaCore/gnat_community_install_script.git /tmp/gnat_install
run /tmp/gnat_install/install_package.sh /tmp/gnat-community-2018-20180524-arm-elf-linux64-bin /opt/adacore-arm-eabi

# installing Javacard SDK
run git clone https://github.com/martinpaljak/oracle_javacard_sdks.git /tmp/oracle_sdks

run groupadd build
run useradd -d /build -ms /bin/bash -g build build;
run usermod -a -G sudo build;

# this is required to allow openocd, dfu-util and pcsc usage when interacting with the device and Javacards from Docker (see README)
run /bin/dash -c 'echo "build    ALL=(ALL) NOPASSWD: /usr/bin/openocd" > /etc/sudoers.d/build; \
                  echo "build    ALL=(ALL) NOPASSWD: /usr/sbin/pcscd" >> /etc/sudoers.d/build; \
                  echo "build    ALL=(ALL) NOPASSWD: /usr/bin/dfu-util" >> /etc/sudoers.d/build; \
                  echo "build    ALL=(ALL) NOPASSWD: /sbin/cfdisk" >> /etc/sudoers.d/build; \
                  echo "build    ALL=(ALL) NOPASSWD: /bin/dd" >> /etc/sudoers.d/build; \
                  chmod 0440 /etc/sudoers.d/build'

user build:build
workdir /build

# adding cross gcc and Gnat toolchains to the user PATH variable
run echo "export PATH=/opt/gcc-arm-none-eabi-6-2017-q2-update/bin:/opt/adacore-arm-eabi/bin:/usr/local/bin:$PATH" > /build/.bashrc;
# now install and set the SDK
run /bin/dash -c 'cd /build; \
                  git config --global color.ui true; \
                  /usr/bin/repo init -u https://github.com/wookey-project/manifest.git -m soft/wookey_stable.xml; \
                  /usr/bin/repo sync'

# local config, corresponding to the local toolchains installation paths
run cd /build; echo 'export CROSS_COMPILE=arm-none-eabi-' > setenv.local.sh; echo 'export JAVA_SC_SDK=/tmp/oracle_sdks/jc303_kit' >> setenv.local.sh

from wookey_builder as wookey_debugger

user root
workdir /tmp

# add debug and flash specific content
run apt-get install -y gdb-multiarch openocd minicom scdaemon libccid pcscd dfu-util

user build:build
workdir /build

cmd ["/bin/bash"] 
