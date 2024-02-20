#!/bin/bash
set -x
set +e

# cat <<EOT >> .netrc
# machine $(echo $GITEA_BASE_URL | awk -F/ '{print $3}')
#        login $GIT_USERNAME
#        password $GIT_PASSWORD
# EOT

# git config --global user.email "$GIT_USERNAME@example.com"
# git config --global user.name "$GIT_USERNAME"

# for serviceName in product-service order-service shipping-service; do
# {{ git_protocol }}://{{ git_host }}
#     cd $serviceName && git init -b $SESSION_NAMESPACE && git remote add origin $GIT_PROTOCOL://$GIT_HOST/${serviceName}.git && git add . && git commit -m "Initial implementation" && git push -u origin $SESSION_NAMESPACE -f
#     cd ~
# done

#git init -b $SESSION_NAMESPACE && git remote add origin $GIT_PROTOCOL://$GIT_HOST//externalized-configuration.git && git add . && git commit -m "Initial implementation" && git push -u origin $SESSION_NAMESPACE -f

(cd /opt/git/repositories && git init && git config --global --add safe.directory /opt/git/repositories && git instaweb)

for serviceName in order-service shipping-service product-service; do
    sed -i 's~REGISTRY_HOST~'"$REGISTRY_HOST"'~g' samples/spring-cloud-demo/${serviceName}/config/workload.yaml
done

mv samples/spring-cloud-demo/order-service .
mv samples/spring-cloud-demo/shipping-service .
mv samples/spring-cloud-demo/product-service .

(cd ~/samples/externalized-configuration && sed -i 's~NAMESPACE~'"$SESSION_NAMESPACE"'~g' order-service.yaml)