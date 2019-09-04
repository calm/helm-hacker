#!/usr/bin/env bash

set -e

if [[ -z $1 ]]; then
    echo "ERROR: No helm release 'name' provided"
    exit 1
fi

release=${1}

if [[ $(uname) != "Darwin" ]]; then
    echo "ERROR: This hack only works on OS X"
    exit 1
fi

if ! which go &> /dev/null; then
    echo "ERROR: go is not installed.. "
    echo "INSTALL: brew install go"
    exit 1
fi

if ! which yq &> /dev/null; then
    echo "ERROR: yq is not installed.. "
    echo "INSTALL: brew install yq"
    exit 1
fi

if ! which kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed.. "
    echo "INSTALL: brew install kubernetes-cli"
    exit 1
fi

dir_helm=$(go env GOPATH)/src/github.com/helm/helm
if [[ ! -d "${dir_helm}" ]]; then
    echo "RUNNING: go get github.com/helm/helm"
    go get github.com/helm/helm
fi

cd "${dir_helm}/_proto"

version=$(kubectl -n kube-system get cm | grep ${release} | cut -d' ' -f1 | cut -d'.' -f2 | sort --version-sort -r | head -1)
if [[ -z ${version} ]]; then
    echo "ERROR: configmap version not found for release=${release}"
    exit 1
fi

file_bak="/tmp/helm-hacker/${release}.${version}.bak.yaml"
file_tmp="/tmp/helm-hacker/${release}.${version}.yaml"
echo "Creating backup of configmap: ${release}.${version} at ${file_bak}"
mkdir -p /tmp/helm-hacker &>/dev/null ||:
kubectl -n kube-system get cm "${release}.${version}" -o yaml > "${file_bak}"

echo "Going to edit configmap: ${release}.${version}"
kubectl -n kube-system get cm "${release}.${version}" -o yaml | grep release | cut -d' ' -f4 | base64 -D | gunzip | protoc --decode hapi.release.Release hapi/**/* > "${file_tmp}"
vim "${file_tmp}"
echo "Serializing protobuf, gzipping and base64-ing"
cat "${file_tmp}" | protoc --encode hapi.release.Release hapi/**/* | gzip | base64 | pbcopy
echo "Updating configmap: ${release}.${version}"
kubectl -n kube-system get cm "${release}.${version}" -o yaml | yq w - data.release "$(pbpaste)" | kubectl apply -f -

echo
echo "If you changed the helm state from FAILED to DEPLOYED, be sure to update 'metadata.labels.STATUS' also in ${release}.${version}"
echo "    kubectl -n kube-system edit cm ${release}.${version}"
