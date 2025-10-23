FROM registry.ci.openshift.org/ocp/4.20:installer AS builder

ARG DIRECT_DOWNLOAD=false
ENV ISO_HOST=https://releases-rhcos--prod-pipeline.apps.int.prod-stable-spoke1-dc-iad2.itup.redhat.com

USER root:root

RUN dnf install -y jq wget coreos-installer
COPY fetch_image.sh /usr/local/bin/
RUN /usr/local/bin/fetch_image.sh

FROM registry.ci.openshift.org/ocp/4.20:cli AS cli
FROM registry.ci.openshift.org/ocp/4.20:base-rhel9

RUN dnf install -y jq && dnf clean all && rm -rf /var/cache/*

COPY --from=builder /usr/bin/coreos-installer /usr/bin/
COPY --from=builder /output/coreos/* /coreos/
COPY --from=cli /usr/bin/oc /usr/bin/

COPY scripts/* /bin/

# Include this container in the release image payload
LABEL io.openshift.release.operator=true
