.SILENT:
.DEFAULT_GOAL := help

MAKESTER__REPO_NAME = loum

# Tagging convention used: <UBUNTU_CODE>-<AIRFLOW-VERSION>-<MAKESTER__RELEASE_NUMBER>
AIRFLOW_VERSION := 2.2.3
AIRFLOW_EXTRAS := "celery,redis,postgres"
PYTHON_MAJOR_MINOR_VERSION := 3.8
PYTHON_RELEASE_VERSION := 10
UBUNTU_CODE := focal
PYTHON_BASE_IMAGE := loum/python3-ubuntu:$(UBUNTU_CODE)-$(PYTHON_MAJOR_MINOR_VERSION).$(PYTHON_RELEASE_VERSION)
PYTHON_VERSION := ${PYTHON_MAJOR_MINOR_VERSION}.${PYTHON_RELEASE_VERSION}
AIRFLOW_PIP_VERSION := 22.0.3
MAKESTER__VERSION = $(UBUNTU_CODE)-$(AIRFLOW_VERSION)
MAKESTER__RELEASE_NUMBER = 1

include makester/makefiles/makester.mk
include makester/makefiles/docker.mk
include makester/makefiles/python-venv.mk

DEV_APT_DEPS := "apt-transport-https\
 apt-utils\
 build-essential\
 ca-certificates\
 gnupg\
 dirmngr\
 ldap-utils\
 libffi-dev\
 libkrb5-dev\
 libpq-dev\
 libsasl2-2\
 libsasl2-dev\
 libsasl2-modules\
 libssl-dev\
 locales\
 lsb-release\
 nodejs\
 openssh-client\
 postgresql-client\
 python3-cairo\
 python3-selinux\
 sasl2-bin\
 software-properties-common\
 unixodbc\
 unixodbc-dev\
 yarn"

RUNTIME_APT_DEPS := "apt-transport-https\
 ca-certificates\
 curl\
 dumb-init\
 gnupg\
 ldap-utils\
 libffi7\
 libsasl2-2\
 libsasl2-modules\
 libssl1.1\
 locales\
 lsb-release\
 netcat\
 openssh-client\
 postgresql-client\
 sasl2-bin\
 unixodbc"

MAKESTER__CONTAINER_NAME := airflow
MAKESTER__IMAGE_TARGET_TAG := $(AIRFLOW_VERSION)-$(PYTHON_MAJOR_MINOR_VERSION).${PYTHON_RELEASE_VERSION}
MAKESTER__BUILD_COMMAND = $(DOCKER) build --rm\
 --no-cache\
 --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION)\
 --build-arg AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS)\
 --build-arg PYTHON_MAJOR_MINOR_VERSION=$(PYTHON_MAJOR_MINOR_VERSION)\
 --build-arg PYTHON_BASE_IMAGE=$(PYTHON_BASE_IMAGE)\
 --build-arg AIRFLOW_CONSTRAINTS=constraints\
 --build-arg AIRFLOW_CONSTRAINTS_REFERENCE=constraints-$(AIRFLOW_VERSION)\
 --build-arg INSTALL_MYSQL_CLIENT="false"\
 --build-arg DEV_APT_DEPS=$(DEV_APT_DEPS)\
 --build-arg RUNTIME_APT_DEPS=$(RUNTIME_APT_DEPS)\
 --build-arg AIRFLOW_PIP_VERSION=$(AIRFLOW_PIP_VERSION)\
 -t $(MAKESTER__SERVICE_NAME):$(MAKESTER__IMAGE_TARGET_TAG) airflow

CMD ?= --help
MAKESTER__CONTAINER_NAME := airflow-base
MAKESTER__RUN_COMMAND := $(DOCKER) run --rm -ti\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__SERVICE_NAME):$(HASH) $(CMD)

MAKESTER__IMAGE_TARGET_TAG = $(HASH)

init: clear-env makester-requirements

set-airflow:
	cd airflow; $(GIT) checkout $(AIRFLOW_VERSION)
build-image: set-airflow

airflow-version:
	$(MAKE) run CMD=version

python:
	$(MAKE) run CMD='bash -c "python3"'

python-version:
	$(MAKE) run CMD='bash -c "python3 --version"'

help: makester-help docker-help python-venv-help
	@echo "(Makefile)\n\
  login                Login to running container $(MAKESTER__CONTAINER_NAME) as user \"airflow\"\n\
  airflow-version      Airflow version\n\
  python3-version      Python3 version\n\
  python               Start the Python3 interpreter\n"

.PHONY: help
