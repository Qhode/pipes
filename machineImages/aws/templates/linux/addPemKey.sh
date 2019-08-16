#!/bin/bash -e

add_pem_key() {
  mkdir -p /tmp
  touch "$SSH_BASTION_PRIVATE_KEY_PATH"
  local key=$(shipctl get_integration_resource_field "$PEM_KEY_RES" "KEY")
  echo "$key" > "$SSH_BASTION_PRIVATE_KEY_PATH"
  chmod 400 "$SSH_BASTION_PRIVATE_KEY_PATH"
  ls -la "$SSH_BASTION_PRIVATE_KEY_PATH"
}

add_pem_key
