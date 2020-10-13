#!/bin/sh -xe

wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/jq
chmod +x ~/jq

# Create values.yaml for ArgoCD app of apps
cd distributions/"$DISTRIBUTION"/terraform || exit
terraform show --json > "$ARTIFACTS_DIR"/terraform.tfstate.json
cd -

cat << EOF > "$ARTIFACTS_DIR/values.yaml"
---
spec:
  source:
    repoURL: $REPO_URL
    targetRevision: $CLUSTER_NAME

baseDomain: $(~/jq -r '.values.root_module.resources[]|select(.type=="docker_container" and .name=="k3s_server").values.ip_address|gsub("\\.";"-") + ".nip.io"' "$ARTIFACTS_DIR/terraform.tfstate.json")
EOF
