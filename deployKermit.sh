#!/bin/bash -e

_exec_cmd(){
  exec_string="$1"
  echo "Executing command: $exec_string"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$exec_string"
  echo "-------------------------------------="
}

set_context() {
  echo "CURR_JOB=$JOB_NAME"
  echo "DEPLOY_VERSION=$DEPLOY_VERSION"
  echo "BASTION_USER=$BASTION_USER"
  echo "BASTION_IP=$BASTION_IP"
  echo "ONEBOX_USER=$ONEBOX_USER"
  echo "ONEBOX_IP=$ONEBOX_IP"
}

configure_ssh_creds() {
  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  pushd $(shipctl get_resource_meta "$RES_PEM")
  if [ ! -f "integration.json" ]; then
    echo "No credentials file found at location: $RES_PEM"
    return 1
  fi

  cat integration.json | jq -r '.key' > key.pem
  chmod 600 key.pem

  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add key.pem
  echo "SSH key added successfully"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
#  echo "Executing inspect command: $inspect_command"
#  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$inspect_command"
#  echo "-------------------------------------="

  _exec_cmd "$inspect_command"

  popd
}

pull_ribbit_repo() {
  echo "Pull ribbit-repo started"
  local pull_cmd="git -C /home/ubuntu/ribbit pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_cmd"
  echo "Successfully pulled ribbit-repo"
}

pull_images() {
  echo "Pulling images to deploy for $DEPLOY_VERSION to OneBox"
  echo "AWS login has occurred, will need to change once we move to artifactory"
  echo "--------------------------------------"

  local login_command="sudo $(aws ecr get-login --no-include-email --region us-east-1)"
  echo "--------------------------------------"
  echo "Executing login command: $login_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$login_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KRIBBIT_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing pull command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KWWW_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing pull command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KAPI_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing pull command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KMICRO_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing pull command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"
}

temp_tag(){
  local tag_command="sudo docker tag $KRIBBIT_IMG:$DEPLOY_VERSION drydock/ribbit:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing tag command: $tag_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$tag_command"
  echo "-------------------------------------"

  local tag_command="sudo docker tag $KWWW_IMG:$DEPLOY_VERSION drydock/www:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing tag command: $tag_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$tag_command"
  echo "-------------------------------------"

  local tag_command="sudo docker tag $KAPI_IMG:$DEPLOY_VERSION drydock/api:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing tag command: $tag_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$tag_command"
  echo "-------------------------------------"

  local tag_command="sudo docker tag $KMICRO_IMG:$DEPLOY_VERSION drydock/kmicro:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing tag command: $tag_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$tag_command"
  echo "-------------------------------------"
}

deploy() {
  echo "Deploying the release $DEPLOY_VERSION to OneBox"
  echo "--------------------------------------"

  local deploy_command="sudo /home/ubuntu/ribbit/ribbit upgrade"
  echo "Executing deploy command: $deploy_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$deploy_command"
  echo "-------------------------------------="

  echo "Successfully deployed release $DEPLOY_VERSION to Onebox env"
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$DEPLOY_VERSION" > "$JOB_STATE/$CURR_JOB.env" #adding version state
  echo "Completed creating a state file for" $CURR_JOB
}

main() {
  eval $(ssh-agent -s)
  set_context
  configure_ssh_creds
  pull_ribbit_repo
  pull_images
  temp_tag
  deploy
#  create_version
}

main
