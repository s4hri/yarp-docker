FROM ubuntu:22.04

ARG BASE_DIR=/usr/local/src/robotology
ARG YCM_TAG_VER=v0.16.9
ARG YARP_TAG_VER=v3.9.0

ARG YARP_PARAMS="-DCMAKE_BUILD_TYPE=Release -DYARP_COMPILE_libYARP_math=ON -DYARP_COMPILE_BINDINGS=ON \
                 -DCREATE_PYTHON=ON -DENABLE_yarpcar_h264=ON \
                 -DYARP_USE_OPENCV=ON -DENABLE_yarpmod_opencv_grabber=ON -DENABLE_yarpcar_mjpeg=ON \
                 -DENABLE_yarpmod_grabber=ON"

ARG YARP_PYTHON3="-DPYTHON_EXECUTABLE=/usr/bin/python3.10"

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Rome

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake pkg-config swig \
    libace-dev libedit-dev libopencv-dev libeigen3-dev \
    python3 python3-dev python3-pip libsqlite3-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    ca-certificates tzdata x11-apps mesa-utils pulseaudio-utils \
    alsa-utils ffmpeg libasound2-plugins alsa-ucm-conf x11-xserver-utils \
    nano vim  curl wget openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/ssh \
    && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

# Add sound configuration
COPY asound.conf /etc/asound.conf

WORKDIR ${BASE_DIR}

RUN cd $BASE_DIR && \
    git clone https://github.com/robotology/ycm -b $YCM_TAG_VER && \
    cd ycm && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install;

RUN cd $BASE_DIR && \
    git clone https://github.com/robotology/yarp -b $YARP_TAG_VER && \
    cd yarp && \
    mkdir build && \
    cd build && \
    cmake .. $YARP_PARAMS && \
    make -j$(nproc) && \
    make install;

RUN cd $BASE_DIR/yarp/build/bindings && \
    cmake .. $YARP_PYTHON3 && \
    make -j$(nproc) && \
    make install;

ENV PYTHONPATH=$BASE_DIR/yarp/build/lib/python3
ENV YARP_DIR=$BASE_DIR/yarp/build
ENV YARP_DATA_DIRS=$YARP_DIR/share/yarp
ENV PATH=$YARP_DIR/bin:$PATH

COPY ./tests ${BASE_DIR}/tests
