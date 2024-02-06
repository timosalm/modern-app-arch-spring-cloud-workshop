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
# cd ~/samples/externalized-configuration
# for serviceName in product-service order-service shipping-service; do
#     sed -i 's/SESSION_NAMESPACE/'"$SESSION_NAMESPACE"'/g' ${serviceName}.yaml
# done
# git init -b $SESSION_NAMESPACE && git remote add origin $GIT_PROTOCOL://$GIT_HOST//externalized-configuration.git && git add . && git commit -m "Initial implementation" && git push -u origin $SESSION_NAMESPACE -f
# cd ~