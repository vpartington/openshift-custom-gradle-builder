# This image is based on openshift/origin-custom-docker-builder, but adds
# support for Gradle builds. It expects a set of environment variables to
# parameterize the build:
#
#   OUTPUT_REGISTRY - the Docker registry URL to push this image to
#   OUTPUT_IMAGE - the name to tag the image with
#   SOURCE_URI - a URI to fetch the build context from
#   SOURCE_REF - a reference to pass to Git for which commit to use (optional)
#
# This image expects to have the Docker socket bind-mounted into the container.
# If "/root/.dockercfg" is bind mounted in, it will use that as authorization
# to a Docker registry.
#
FROM openshift/origin-base

RUN INSTALL_PKGS="gettext automake make docker java-1.8.0-openjdk-devel" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

LABEL io.k8s.display-name="OpenShift Custom Gradle Builder"
ENV HOME=/root
COPY build.sh /tmp/build.sh
CMD ["/tmp/build.sh"]
