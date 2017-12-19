#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
  TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
fi

if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
  URL="${SOURCE_REPOSITORY}"
  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
    URL="https://${URL}"
  fi
  curl --head --silent --fail --location --max-time 16 $URL > /dev/null
  if [ $? != 0 ]; then
    echo "Could not access source url: ${SOURCE_REPOSITORY}"
    exit 1
  fi
fi

BUILD_DIR=$(mktemp --directory)
git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}"
if [ $? != 0 ]; then
  echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
  exit 1
fi
pushd "${BUILD_DIR}"
git checkout "${SOURCE_REF}"
if [ $? != 0 ]; then
  echo "Error trying to checkout branch: ${SOURCE_REF}"
  exit 1
fi

./gradlew pushDockerImage -Doutput.registry=${OUTPUT_REGISTRY} -Doutput.image=${OUTPUT_IMAGE}
if [ $? != 0 ]; then
  exit 1
fi

popd

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi
