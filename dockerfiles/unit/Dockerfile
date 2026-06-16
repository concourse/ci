ARG base_image=concourse/golang-builder
FROM ${base_image}

ARG TARGETARCH

# enable CGO so we can go test with -race
ENV CGO_ENABLED=1

# tools needed for running some tests and installing other dependencies
RUN apk --no-cache --no-progress add \
    btrfs-progs \
    ca-certificates \
    # install Chrome for Puppeteer (watsjs /upgrade/downgrade/smoke tests)
    chromium \
    curl \
    # for local integration tests
    docker \
    docker-compose \
    file \
    git \
    # for CGO enabled tests
    gcc \
    gnupg \
    gnutar \
    grep \
    # for k8s-topgun tests
    kubectl \
    helm \
    iproute2 \
    jq \
    # for baggageclaim tests
    losetup \
    mount \
    umount \
    # baggageclaim tests, to allow us
    bpftool \
    clang \
    libbpf-dev \
    nodejs-22 \
    npm \
    # for shasum cli
    perl-utils \
    # used for /atc/db tests
    postgresql-17 \
    postgresql-17-client \
    postgresql-17-contrib \
    # for bin-smoke test
    terraform \
    cmd:ssh-keygen \
    google-cloud-sdk \
    gke-gcloud-auth-plugin \
    unzip \
    # for bosh-topgun tests
    vault \
    yq \
    # for Windows artifact packaging
    zip

# Wolfi's postgres packages don't create a postgres user which the atc/db tests
# expect to be present when running as UID=0
RUN adduser -D postgres

# ensure that Puppeteer uses this Chrome instead of downloading on demand
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/sbin/chromium

# install Yarn for web UI tests
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN npm install -g corepack &&\
    yarn set version stable

# install BOSH CLI for bosh-smoke, bosh-topgun
ARG BOSH_VERSION=7.10.3
RUN curl -L "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-${TARGETARCH}" \
    -o /usr/sbin/bosh && \
    chmod +x /usr/sbin/bosh

# install Let's Encrypt staging cert for 'curl', setting an env var just so
# it's easier to discover if/when this changes again
ENV LETS_ENCRYPT_STAGING_CA_CERT=/usr/local/share/ca-certificates/letsencrypt-stg-root-x1.crt
RUN curl https://letsencrypt.org/certs/staging/letsencrypt-stg-root-x1.pem -o $LETS_ENCRYPT_STAGING_CA_CERT && \
    update-ca-certificates

# install Let's Encrypt staging cert to nssdb for Chrome
RUN apk --no-cache --no-progress add libnss-tools
RUN mkdir -p /root/.pki/nssdb && \
    chmod 700 /root/.pki/nssdb && \
    certutil -N -d sql:/root/.pki/nssdb --empty-password && \
    certutil -A \
    -n "LetsEncrypt Staging Fake Root" \
    -t "TCu,Cu,Tu" \
    -i $LETS_ENCRYPT_STAGING_CA_CERT \
    -d sql:/root/.pki/nssdb

# install goimports CLI for formatting go files
RUN go install golang.org/x/tools/cmd/goimports@latest
