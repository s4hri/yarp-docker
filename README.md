# yarp-docker


# How to build

    docker compose build

# How to run

    xhost +local:docker
    docker compose up

# How to test 

## Testing YARP

    docker compose --profile test up yarp.test

## Testing X server and audio

    xhost +local:docker
    docker compose run yarp bash tests/test_utils.sh
