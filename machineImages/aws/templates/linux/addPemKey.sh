#!/bin/bash -e

add_pem_key() {
  mkdir -p ~/.ssh
  touch $SSH_BASTION_PRIVATE_KEY
  local key=$(shipctl get_integration_resource_field "$PEM_KEY_RES" "KEY")
  echo "$key" > $SSH_BASTION_PRIVATE_KEY
  chmod 400 $SSH_BASTION_PRIVATE_KEY
}

add_pem_key
