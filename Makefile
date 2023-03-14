.SILENT:
.DEFAULT_GOAL := help

MAKESTER__INCLUDES := py docker
MAKESTER__REPO_NAME = loum

include makester/makefiles/makester.mk

#
# Makester overrides.
#
# Container image build
# Tagging convention used: <UBUNTU_CODE>-<AIRFLOW-VERSION>-<MAKESTER__RELEASE_NUMBER>
AIRFLOW_VERSION ?= 2.5.0
AIRFLOW_EXTRAS := "celery,redis,postgres"
PYTHON_MAJOR_MINOR_VERSION := 3.10
UBUNTU_CODE := jammy
PYTHON_BASE_IMAGE := loum/python3-ubuntu:$(UBUNTU_CODE)-$(PYTHON_MAJOR_MINOR_VERSION)
AIRFLOW_PIP_VERSION := 23.0.1
MAKESTER__VERSION = $(UBUNTU_CODE)-$(AIRFLOW_VERSION)
MAKESTER__RELEASE_NUMBER = 1

DEV_APT_COMMAND := ""

# Override to suit Ubuntu jammy.
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

MAKESTER__IMAGE_TARGET_TAG := jammy-$(AIRFLOW_VERSION)

MAKESTER__BUILD_COMMAND = --rm --no-cache\
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
 --tag $(MAKESTER__IMAGE_TAG_ALIAS) -f airflow/Dockerfile.airflow-base airflow

CMD ?= --help
MAKESTER__CONTAINER_NAME := airflow-base
MAKESTER__RUN_COMMAND := $(MAKESTER__DOCKER) run --rm -ti\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__IMAGE_TAG_ALIAS) $(CMD)

#
# Local Makefile targets.
#
# Initialise the development environment.
init: py-venv-clear py-venv-init py-install-makester

_set-airflow:
	cd airflow; $(GIT) checkout $(AIRFLOW_VERSION)

_unset-airflow:
	cd airflow; $(GIT) checkout main

_customise-dockerfile:
	cat airflow/Dockerfile | sed -E "s/^RUN bash \/scripts\/docker\/install_os_dependencies.sh /USER root\nRUN bash \/scripts\/docker\/install_os_dependencies.sh /" > airflow/Dockerfile.airflow-base

_customise-dockerfile-rm:
	-@$(shell which rm) airflow/Dockerfile.airflow-base

project-image-build: _set-airflow _customise-dockerfile image-buildx _unset-airflow _customise-dockerfile-rm

image-bulk-build:
	$(info ### Container image bulk build ...)
	scripts/bulkbuild.sh

image-pull-into-docker:
	$(info ### Pulling local registry image $(MAKESTER__IMAGE_TAG_ALIAS) into docker)
	$(MAKESTER__DOCKER) pull $(MAKESTER__IMAGE_TAG_ALIAS)

image-tag-in-docker: image-pull-into-docker
	$(info ### Tagging local registry image $(MAKESTER__IMAGE_TAG_ALIAS) => $(MAKESTER__STATIC_SERVICE_NAME):$(MAKESTER__RELEASE_VERSION))
	$(MAKESTER__DOCKER) tag $(MAKESTER__IMAGE_TAG_ALIAS) $(MAKESTER__STATIC_SERVICE_NAME):$(MAKESTER__RELEASE_VERSION)

image-transfer: image-tag-in-docker
	$(info ### Deleting pulled image $(MAKESTER__IMAGE_TAG_ALIAS))
	$(MAKESTER__DOCKER) rmi $(MAKESTER__IMAGE_TAG_ALIAS)

multi-arch-build: image-registry-start image-buildx-builder
	$(info ### Starting multi-arch builds ...)
	$(MAKE) _set-airflow _customise-dockerfile
	$(MAKE) MAKESTER__DOCKER_PLATFORM=linux/arm64,linux/amd64 image-buildx
	$(MAKE) _unset-airflow _customise-dockerfile-rm
	$(MAKE) image-transfer
	$(MAKE) image-registry-stop

airflow-version:
	$(MAKE) container-run CMD=version

python:
	$(MAKE) container-run CMD='bash -c "python3"'

python3-version:
	$(MAKE) container-run CMD='bash -c "python3 --version"'

help: makester-help
	@echo "(Makefile)\n\
  airflow-version      Airflow version\n\
  init                 Build the local development environment\n\
  image-bulk-build     Build all multi-platform container images\n\
  multi-arch-build     Convenience target for multi-arch container image builds\n\
  project-image-build  Customised image builder\n\
  python               Start the Python3 interpreter\n\
  python3-version      Python3 version\n"

.PHONY: help
