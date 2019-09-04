# Helm Hacker

## Introduction

Hack the helm state, because sometimes you need to!

## Contents

- [Install](#install)
- [Usage](#usage)
- [How it works](#how-it-works)
- [References](#references)

## Install

```bash
brew tap calm/calm
brew install helm-hacker
```

## Usage

First, make sure you're able to connect to your kubernetes cluster. Then update your helm chart state using:

```bash
helm-hacker RELEASE_NAME
```

## How it Works

Helm keeps it's state in configmaps in the `kube-system` namespace. The configmap state is protobuf encoded, gzipped, and base64'd. So, you have to undo all those layers to edit it. Then, you have to reapply all those layers to update the configmap. This script does all of that.

For additional information, see references below.

## References

- https://medium.com/@valercara/helm-stuck-in-pending-update-and-how-to-fix-it-13c4b2eaf9f7
