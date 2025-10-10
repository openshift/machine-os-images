FROM registry.ci.openshift.org/ocp/4.21:installer AS builder

ARG DIRECT_DOWNLOAD=false
ENV ISO_HOST=https://releases-rhcos--prod-pipeline.apps.int.prod-stable-spoke1-dc-iad2.itup.redhat.com
# NOTE(elfosardo): dummy env variable to update when we need to rebuild the image without
# actual changes; output of `date +%Y-%m-%d_%H-%M-%S`
ENV DUMMY_REBUILD_TIMESTAMP=2025-10-03_18-18-19

USER root:root

RUN dnf install -y jq wget coreos-installer
COPY fetch_image.sh /usr/local/bin/
RUN /usr/local/bin/fetch_image.sh

FROM registry.ci.openshift.org/ocp/4.21:cli AS cli
FROM registry.ci.openshift.org/ocp/4.21:base-rhel9

COPY --from=builder /usr/bin/coreos-installer /usr/bin/
COPY --from=builder /output/coreos/* /coreos/
COPY --from=cli /usr/bin/oc /usr/bin/

COPY scripts/* /bin/

# Include this container in the release image payload
LABEL io.openshift.release.operator=true
