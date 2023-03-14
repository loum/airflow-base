#!/bin/sh

for AIRFLOW_VERSION in 2.3.3 2.3.4 2.4.0 2.4.1 2.4.2 2.4.3 2.5.0 2.5.1
do
    MAKESTER__DOCKER_PLATFORM=linux/arm64,linux/amd64\
 MAKESTER__DOCKER_DRIVER_OUTPUT=push\
 AIRFLOW_VERSION=$AIRFLOW_VERSION\
 make project-image-build
done
