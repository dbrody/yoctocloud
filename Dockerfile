FROM ubuntu:14.04

RUN apt-get update && apt-get -y upgrade

RUN df -k

# Install the following utilities (required by poky)
RUN apt-get install -y build-essential chrpath curl diffstat gcc-multilib gawk git-core libsdl1.2-dev texinfo unzip wget xterm
RUN apt-get install -y nano

# Additional host packages required by poky/scripts/wic
RUN apt-get install -y bzip2 dosfstools mtools parted syslinux tree

# Add "repo" tool (used by many Yocto-based projects)
RUN curl http://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo

# Create user "jenkins"
RUN id jenkins 2>/dev/null || useradd --uid 1000 --create-home jenkins

# Create a non-root user that will perform the actual build
RUN id build 2>/dev/null || useradd --uid 30000 --create-home build
RUN echo "build ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

# MOVE TO BASH
RUN ln -snf /bin/bash /bin/sh

USER build
WORKDIR /home/build

# Make Yocto

RUN mkdir -p ~/yocto && sudo chown build.build ~/yocto
RUN cd ~/yocto && git clone git://git.yoctoproject.org/poky
RUN cd ~/yocto/poky && git clone git://git.yoctoproject.org/meta-raspberrypi

# Add Node
RUN cd ~/yocto/poky && git clone https://github.com/imyller/meta-nodejs.git

# Copy Files
COPY run_yocto_build.sh /home/build/
COPY local.conf /home/build/
COPY bblayers.conf /home/build/


# Make Base Yocto....
RUN /bin/bash -c "sudo locale-gen en_US en_US.UTF-8"
RUN /bin/bash -c "sudo dpkg-reconfigure locales"

# Switch to Poky dir
RUN cd ~/yocto/poky && source ./oe-init-build-env build

COPY local.conf /home/build/yocto/poky/build/conf/
COPY bblayers.conf /home/build/yocto/poky/build/conf/

# Run the build....
# Build Base RPI Image
RUN cd ~/yocto/poky && source ./oe-init-build-env build && export LC_ALL="en_US.UTF-8" && bitbake rpi-basic-image

# Build Node JS
RUN sudo apt-get install -y gcc-multilib g++-multilib
RUN cd ~/yocto/poky && source ./oe-init-build-env build && export LC_ALL="en_US.UTF-8" && bitbake nodejs

CMD [ "/bin/bash" ]


# RUN sudo chmod +x run_yocto_build.sh

# RUN IT!!!
# CMD [ "./run_yocto_build.sh" ]


# RUN cd ~/ && source ~/poky/oe-init-build-env && bitbake -k core-image-minimal
# EOF
