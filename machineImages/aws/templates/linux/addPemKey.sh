#!/bin/bash -e

add_pem_key() {
  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  pushd $(shipctl get_resource_meta "$PEM_KEY_RES")
  if [ ! -f "integration.json" ]; then
    echo "No credentials file found at location: $PEM_KEY_RES"
    return 1
  fi

  mkdir -p /tmp
  cat integration.json | jq -r '.key' > "$SSH_BASTION_PRIVATE_KEY_PATH"
  chmod 600 "$SSH_BASTION_PRIVATE_KEY_PATH"

  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add "$SSH_BASTION_PRIVATE_KEY_PATH"
  echo "SSH key added successfully"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  ls -la "$SSH_BASTION_PRIVATE_KEY_PATH"

  popd
}

add_pem_key
