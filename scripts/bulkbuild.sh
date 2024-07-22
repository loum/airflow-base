#!/bin/sh

for AIRFLOW_VERSION in 2.7.2 2.7.3 2.8.0 2.8.1 2.8.2 2.8.3 2.8.4 2.9.0 2.9.1 2.9.2 2.9.3
do
    MAKESTER__DOCKER_PLATFORM=linux/arm64,linux/amd64\
 MAKESTER__DOCKER_DRIVER_OUTPUT=push\
 AIRFLOW_VERSION=$AIRFLOW_VERSION\
 make project-image-build
done
