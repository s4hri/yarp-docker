ARG DOCKER_SRC

FROM $DOCKER_SRC
LABEL maintainer="Davide De Tommaso <davide.detommaso@iit.it>"

ARG YARP_TAG_VER
ARG YCM_TAG_VER
ARG ROBOT_CODE="/usr/local/src/robot"

ARG YARP_PARAMS="-DYARP_COMPILE_libYARP_math=ON -DYARP_COMPILE_BINDINGS=ON \
                 -DCREATE_PYTHON=ON -DENABLE_yarpcar_h264=ON \
                 -DYARP_USE_OPENCV=ON -DENABLE_yarpmod_opencv_grabber=ON -DENABLE_yarpcar_mjpeg=ON \
                 -DENABLE_yarpmod_grabber=ON"

ARG YARP_PYTHON3="-DPYTHON_EXECUTABLE=/usr/bin/python3.8 \
                  -DPYTHON_INCLUDE_DIR=/usr/include/python3.8 \
                  -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.8.so"

ENV TZ=Europe/Rome
ENV DEBIAN_FRONTEND noninteractive
ENV ROBOT_CODE $ROBOT_CODE

RUN mkdir -p $ROBOT_CODE

RUN cd $ROBOT_CODE && \
    git clone https://github.com/robotology/ycm -b $YCM_TAG_VER && \
    cd ycm && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install;

RUN cd $ROBOT_CODE && \
    git clone https://github.com/robotology/yarp -b $YARP_TAG_VER && \
    cd yarp && \
    mkdir build && \
    cd build && \
    cmake .. $YARP_PARAMS && \
    make -j$(nproc) && \
    make install;

RUN cd $ROBOT_CODE/yarp/build/bindings && \
    cmake .. $YARP_PYTHON3 && \
    make -j$(nproc) && \
    make install;

ENV PYTHONPATH=$PYTHONPATH:$ROBOT_CODE/yarp/build/lib/python3

RUN mkdir -p /home/icub/.config/yarp
COPY yarp.conf /home/icub/.config/yarp
