# Airflow Base Container Image

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [(macOS Users only) upgrading GNU Make](#macos-users-only-upgrading-gnu-make)
  - [Creating the local environment](#creating-the-local-environment)
- [Help](#help)
- [Container Image Management](#container-image-management)
- [Interact with Apache Airflow](#interact-with-apache-airflow)

## Overview
This repository integrates the [Apache Airflow code base](https://github.com/apache/airflow) as a Git submodule and is primarily used to build a vanilla base Docker image.  This base can then be extended with your workflow capability to create an immutable artifact.

Why not use the Airflow images [Oprovided?  Mainly because we use [Ubuntu as the underlying OS](https://github.com/loum/python3-ubuntu) as we need more currency to mitigate CVEs.

[top](#airflow-base-container-image)

## Quick Links
- [Ubuntu](https://ubuntu.com/)
- [Python](https://www.python.org/)
- [Apache Airflow](https://airflow.apache.org/)

[top](#airflow-base-container-image)

## Prerequisites
- [Docker](https://docs.docker.com/install/)
- [GNU make](https://www.gnu.org/software/make/manual/make.html)
- Python 3 Interpreter. [We recommend installing pyenv](https://github.com/pyenv/pyenv).

[top](#airflow-base-container-image)

### (macOS Users only) Upgrading GNU Make
Although the macOS machines provide a working GNU `make` it is too old to support the capabilities within the DevOps utilities
package, [makester](https://github.com/loum/makester).  Instead, it is recommended to upgrade to the GNU make version provided
by Homebrew.  Detailed instructions can be found at https://formulae.brew.sh/formula/make.  In short, to upgrade GNU make run:
```
brew install make
```
The `make` utility installed by Homebrew can be accessed by `gmake`.  The https://formulae.brew.sh/formula/make notes suggest how you can update your local `PATH` to use `gmake` as `make`.  Alternatively, alias `make`:
```
alias make=gmake
```

[top](#airflow-base-container-image)

## Getting Started
[Makester](https://loum.github.io/makester/) is used as the Integrated Developer Platform.

### (macOS Users only) upgrading GNU Make
Follow [these notes](https://loum.github.io/makester/macos/#upgrading-gnu-make-macos) to get [GNU make](https://www.gnu.org/software/make/manual/make.html).

### Creating the local environment
Get the code and change into the top level `git` project directory:
```
git clone https://github.com/loum/airflow-base.git && cd airflow-base
```
For first-time setup, get the [Makester project](https://github.com/loum/makester.git):
```
git submodule update --init
```
Initialise the environment:
```
make init
```

[top](#airflow-base-container-image)

## Help
There should be a `make` target to be able to get most things done.  Check the help for more information:
```
make help
```

[top](#airflow-base-container-image)

## Container Image Management
> **_NOTE:_**  See [Makester's `docker` subsystem](https://loum.github.io/makester/makefiles/docker/) for more detailed container image operations.

Build the container image locally:
```
make project-image-build
```

Search for built container image:
```
make image-search
```

Delete the container image:
```
make image-rm
```

[top](#airflow-base-container-image)

## Interact with Apache Airflow
To get the Apache Airflow version:
```
make airflow-version
```
To get the Apache-Airflow CLI help:
```
make container-run
```
To get the Python3 version:
```
make python3-version
```

---
[top](#airflow-base-container-image)
