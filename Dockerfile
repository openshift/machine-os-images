FROM registry.ci.openshift.org/ocp/4.19:installer AS builder

ARG DIRECT_DOWNLOAD=false
ENV ISO_HOST=https://releases-rhcos-art.apps.ocp-virt.prod.psi.redhat.com


USER root:root

RUN dnf install -y jq wget coreos-installer
COPY fetch_image.sh /usr/local/bin/
RUN /usr/local/bin/fetch_image.sh


FROM registry.ci.openshift.org/ocp/4.19:base-rhel9

COPY --from=builder /usr/bin/coreos-installer /usr/bin/
COPY --from=builder /output/coreos/* /coreos/

COPY scripts/* /bin/

# Include this container in the release image payload
LABEL io.openshift.release.operator=true
