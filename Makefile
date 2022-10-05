.SILENT:
.DEFAULT_GOAL := help

MAKESTER__REPO_NAME = loum

# Tagging convention used: <UBUNTU_CODE>-<AIRFLOW-VERSION>-<MAKESTER__RELEASE_NUMBER>
AIRFLOW_VERSION ?= 2.4.0
AIRFLOW_EXTRAS := "celery,redis,postgres"
PYTHON_MAJOR_MINOR_VERSION := 3.10
UBUNTU_CODE := jammy
PYTHON_BASE_IMAGE := loum/python3-ubuntu:$(UBUNTU_CODE)-$(PYTHON_MAJOR_MINOR_VERSION)
AIRFLOW_PIP_VERSION := 22.2.2
MAKESTER__VERSION = $(UBUNTU_CODE)-$(AIRFLOW_VERSION)
MAKESTER__RELEASE_NUMBER = 1

include makester/makefiles/makester.mk
include makester/makefiles/docker.mk
include makester/makefiles/python-venv.mk

DEV_APT_COMMAND := ""

# Override to suit Ubuntu jammy
RUNTIME_APT_DEPS="apt-transport-https apt-utils ca-certificates\
 curl dumb-init freetds-bin gosu krb5-user\
 ldap-utils libffi7 libldap-2.5-0 libsasl2-2 libsasl2-modules libssl3 locales\
 lsb-release netcat openssh-client python3-selinux rsync sasl2-bin sqlite3 sudo unixodbc"

# These seem to be missing from the base Ubuntu image.
# - dumb-init is used in the Airflow image entrypoint
# - nc (netcat) is used to connect to Redis
# - libpq-dev for "pg_config executable not found" error when pip installing in Airflow 2.4.0
ADDITIONAL_RUNTIME_APT_DEPS := "dumb-init netcat libpq-dev"
ADDITIONAL_DEV_APT_DEPS := "libpq-dev"

MAKESTER__CONTAINER_NAME := airflow
MAKESTER__BUILD_COMMAND = $(DOCKER) build --rm\
 --no-cache\
 --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION)\
 --build-arg AIRFLOW_EXTRAS=$(AIRFLOW_EXTRAS)\
 --build-arg PYTHON_MAJOR_MINOR_VERSION=$(PYTHON_MAJOR_MINOR_VERSION)\
 --build-arg PYTHON_BASE_IMAGE=$(PYTHON_BASE_IMAGE)\
 --build-arg AIRFLOW_CONSTRAINTS=constraints\
 --build-arg AIRFLOW_CONSTRAINTS_REFERENCE=constraints-$(AIRFLOW_VERSION)\
 --build-arg INSTALL_MYSQL_CLIENT="false"\
 --build-arg INSTALL_POSTGRES_CLIENT="false"\
 --build-arg DEV_APT_DEPS=$(DEV_APT_DEPS)\
 --build-arg DEV_APT_COMMAND=$(DEV_APT_COMMAND)\
 --build-arg RUNTIME_APT_DEPS=$(RUNTIME_APT_DEPS)\
 --build-arg ADDITIONAL_RUNTIME_APT_DEPS=$(ADDITIONAL_RUNTIME_APT_DEPS)\
 --build-arg ADDITIONAL_DEV_APT_DEPS=$(ADDITIONAL_DEV_APT_DEPS)\
 --build-arg AIRFLOW_PIP_VERSION=$(AIRFLOW_PIP_VERSION)\
 --build-arg INSTALLATION_TYPE="RUNTIME"\
 -t $(MAKESTER__SERVICE_NAME):$(MAKESTER__IMAGE_TARGET_TAG) airflow

CMD ?= --help
MAKESTER__CONTAINER_NAME := airflow-base
MAKESTER__RUN_COMMAND := $(DOCKER) run --rm -ti\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__SERVICE_NAME):$(HASH) $(CMD)

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
