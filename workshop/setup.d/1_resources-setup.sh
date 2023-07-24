#!/bin/bash
set -x
set +e

kubectl patch serviceaccount default -p '{"secrets": [{"name": "registry-credentials"}], "imagePullSecrets": [{"name": "registry-credentials"}]}'

cp -a samples/spring-cloud-demo/. .
rm -rf samples/spring-cloud-demo