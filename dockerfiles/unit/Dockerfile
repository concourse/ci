FROM concourse/golang-builder

# basic setup for adding new apt sources and installing packages
RUN apt-get update && apt-get -y install \
      apt-transport-https \
      ca-certificates \
      curl \
      iproute2 \
      gnupg2 \
      software-properties-common \
      unzip

# install PostgreSQL for DB tests
ENV DEBIAN_FRONTEND noninteractive
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main"
RUN apt-get update && apt-get -y install postgresql-11
ENV PATH $PATH:/usr/lib/postgresql/11/bin

# install Node 8.x
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && apt-get install -y nodejs

# install Yarn for web UI tests
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main"
RUN apt-get update && apt-get -y install yarn

# install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update && apt-get -y install docker-ce

# install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose && \
      chmod +x /usr/local/bin/docker-compose

# install Chrome for Puppeteer (watsjs)
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN add-apt-repository "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"
RUN apt-get update && apt-get -y install google-chrome-unstable --no-install-recommends

# install BOSH CLI for bosh-smoke, bosh-topgun
RUN curl -L "https://github.com/cloudfoundry/bosh-cli/releases/download/v5.3.1/bosh-cli-5.3.1-linux-amd64" \
      -o /usr/local/bin/bosh && \
      chmod +x /usr/local/bin/bosh

# install kubectl for k8s-related jobs
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
      touch /etc/apt/sources.list.d/kubernetes.list && \
      echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
      apt-get update && \
      apt-get install --no-install-recommends -y kubectl && \
      rm -rf /var/lib/apt/lists/*

# install helm for k8s-related jobs
RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# install Vault for bosh-topgun
RUN curl -L https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip -o /tmp/vault.zip && \
      unzip /tmp/vault.zip -d /usr/local/bin && \
      rm /tmp/vault.zip

# install Terraform, ssh and jq for bin-smoke
RUN curl -fsSL https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip -o /tmp/terraform.zip && \
      unzip /tmp/terraform.zip -d /usr/local/bin && \
      rm /tmp/terraform.zip
RUN apt-get update && apt-get -y install jq openssh-client libnss3-tools
RUN curl -so /etc/ssl/certs/fake_root.pem \
  https://letsencrypt.org/certs/fakelerootx1.pem && \
  chmod 644 /etc/ssl/certs/fake_root.pem && \
  mkdir -p /root/.pki/nssdb && \
  chmod 700 /root/.pki/nssdb && \
  certutil -N -d sql:/root/.pki/nssdb --empty-password && \
  certutil -A \
    -n "LetsEncrypt Staging Fake Root" \
    -t "TCu,Cu,Tu" \
    -i /etc/ssl/certs/fake_root.pem \
    -d sql:/root/.pki/nssdb

# install containerd
ARG RUNC_VERSION=v1.0.0-rc9
ARG CNI_VERSION=v0.8.3
ARG CONTAINERD_VERSION=1.3.2
ARG INIT_VERSION=1.2.2

RUN set -x && \
	mkdir -p /usr/local/concourse/bin && \
	curl -sSL https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
		-o /usr/local/concourse/bin/init && chmod +x /usr/local/concourse/bin/init && \
	curl -sSL https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION.linux-amd64.tar.gz \
		| tar -zvxf - -C /usr/local/concourse/bin --strip-components=1 && \
	curl -sSL https://github.com/opencontainers/runc/releases/download/$RUNC_VERSION/runc.amd64 \
		-o /usr/local/concourse/bin/runc && chmod +x /usr/local/concourse/bin/runc && \
	curl -sSL https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz \
		| tar -zvxf - -C /usr/local/concourse/bin
