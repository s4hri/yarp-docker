ARG DOCKER_SRC

FROM $DOCKER_SRC
LABEL maintainer="Davide De Tommaso <davide.detommaso@iit.it>"

ARG YARP_TAG_VER
ARG YCM_TAG_VER
ARG YARP_DIR="/home/docky/robotology-build"

ARG YARP_PARAMS="-DYARP_COMPILE_libYARP_math=ON -DYARP_COMPILE_BINDINGS=ON \
                 -DCREATE_PYTHON=ON -DENABLE_yarpcar_h264=ON \
                 -DYARP_USE_OPENCV=ON -DENABLE_yarpmod_opencv_grabber=ON -DENABLE_yarpcar_mjpeg=ON \
                 -DENABLE_yarpmod_grabber=ON \
                 -DCMAKE_INSTALL_PREFIX=$YARP_DIR"
ARG YARP_PYTHON3="-DPYTHON_EXECUTABLE=/usr/bin/python3.8 \
                  -DPYTHON_INCLUDE_DIR=/usr/include/python3.8 \
                  -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.8.so"

ENV TZ=Europe/Rome
ENV DEBIAN_FRONTEND noninteractive

USER root

RUN cd /home/docky && \
    git clone https://github.com/robotology/ycm -b $YCM_TAG_VER && \
    cd ycm && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install;

USER docky

RUN cd /home/docky && \
    git clone https://github.com/robotology/yarp -b $YARP_TAG_VER && \
    cd yarp && \
    mkdir build && \
    cd build && \
    cmake .. $YARP_PARAMS && \
    make -j$(nproc) && \
    make install;

RUN cd /home/docky/yarp/build/bindings && \
    cmake .. $YARP_PYTHON3 && \
    make -j$(nproc) && \
    make install;

USER root
RUN cp /home/docky/robotology-build/lib/python3/dist-packages/*.* /usr/lib/python3/dist-packages/
RUN cp -r /home/docky/robotology-build/* /usr/local

USER docky

ENV YARP_DIR ${YARP_DIR}
ENV YARP_DATA_DIRS=${YARP_DIR}/share/yarp
ENV PATH ${YARP_DIR}/bin:$PATH
ENV LD_LIBRARY_PATH ${YARP_DIR}/lib:${LD_LIBRARY_PATH}
