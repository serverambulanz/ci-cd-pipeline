# OpenTofu CLI Container
# Based on Alpine Linux for minimal size

FROM alpine:3.20

# OpenTofu Version
ARG OPENTOFU_VERSION=1.10.6

# Install dependencies
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    unzip \
    wget

# Install OpenTofu
RUN wget -O /tmp/tofu.zip \
    "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip" && \
    unzip /tmp/tofu.zip -d /usr/local/bin/ && \
    rm /tmp/tofu.zip && \
    chmod +x /usr/local/bin/tofu

# Verify installation
RUN tofu version

# Create workspace directory
WORKDIR /workspace

# Default command
CMD ["tofu", "--help"]
