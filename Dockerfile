FROM ghcr.io/vmware-tanzu-labs/educates-jdk17-environment:2.6.16

USER root

RUN curl -L -o /usr/local/bin/kp https://github.com/buildpacks-community/kpack-cli/releases/download/v0.12.1/kp-linux-amd64-0.12.1 && \
  chmod 755 /usr/local/bin/kp

RUN curl -L -o /usr/local/bin/hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 && \
    chmod 755 /usr/local/bin/hey

# Install krew
RUN \
( \
  set -x; cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  KREW="krew-${OS}_${ARCH}" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
  tar zxvf "${KREW}.tar.gz" && \
  ./"${KREW}" install krew \
)
RUN echo "export PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" >> ${HOME}/.bashrc
ENV PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
ENV KUBECTL_VERSION=1.26
RUN kubectl krew install tree
RUN kubectl krew install eksporter
RUN chmod 775 -R $HOME/.krew

# Utilities
RUN yum install moreutils wget ruby git-instaweb -y

RUN wget -O /var/www/git/static/gitweb.css https://raw.githubusercontent.com/kogakure/gitweb-theme/master/gitweb.css

RUN fix-permissions /home/eduk8s
RUN fix-permissions /opt

USER 1001