ARG base_image_tag
FROM ubuntu:${base_image_tag}

RUN apt-get update && apt-get install -y curl
# install osspi-cli
ENV OSSPI_ROOT=/.osspicli
RUN sh -c "OSSPI_HOME="$OSSPI_ROOT" && VERSION="<cli_version>" && $(curl -fsSL https://build-artifactory.eng.vmware.com/osspicli-local/beta/osspicli/install.sh)"
ENV OSSPICLI=$OSSPI_ROOT/osspi/osspi
