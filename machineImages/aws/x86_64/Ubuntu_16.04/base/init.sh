#!/bin/bash
set -e
set -o pipefail

readonly ARCHITECTURE="x86_64"
readonly OS="Ubuntu_16.04"
readonly REQKICK_DIR="/jfrog/reqKick"
readonly NODE_SCRIPTS_LOCATION="/jfrog/nodeInit"
readonly EXECTEMPLATES_DIR="/jfrog/execTemplates"
readonly REQEXEC_DIR="/jfrog/reqExec"
readonly NODE_SCRIPTS_DOWNLOAD_LOCATION="/tmp/node.tar.gz"
readonly NODE_TARBALL_URL="https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/Shippable/kermit-nodeInit/archive/$RUNTIME_VERSION.tar.gz"
readonly REQKICK_DOWNLOAD_URL="https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/Shippable/kermit-reqKick/archive/$RUNTIME_VERSION.tar.gz"
readonly EXECTEMPLATES_DOWNLOAD_URL="https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/Shippable/kermit-execTemplates/archive/$RUNTIME_VERSION.tar.gz"
readonly REPORTS_DOWNLOAD_URL="https://s3.amazonaws.com/shippable-artifacts/pipelines-reports/$RUNTIME_VERSION/reports-$RUNTIME_VERSION-$ARCHITECTURE-$OS.tar.gz"
readonly REQEXEC_DOWNLOAD_URL="https://s3.amazonaws.com/shippable-artifacts/pipelines-reqExec/$RUNTIME_VERSION/reqExec-$RUNTIME_VERSION-$ARCHITECTURE-$OS.tar.gz"
readonly IS_SWAP_ENABLED=false
export INIT_SCRIPT_NAME="Docker_$DOCKER_VERSION.sh"

before_exit() {
  ## flush any remaining console
  echo $1
  echo $2
  echo "AMI build script completed"
}

check_envs() {
  expected_envs=$1
  for env in "${expected_envs[@]}"
  do
    env_value=$(eval "echo \$$env")
    if [ -z "$env_value" ]; then
      echo "Missing ENV: $env"
      exit 1
    fi
  done
}

exec_cmd() {
  local cmd=$@
  eval $cmd
}

exec_grp() {
  local group_name=$1
  eval "$group_name"
}
__process_marker() {
  local prompt="$@"
  echo ""
  echo "# $(date +"%T") #######################################"
  echo "# $prompt"
  echo "##################################################"
}

__process_msg() {
  local message="$@"
  echo "|___ $@"
}

__process_error() {
  local message="$1"
  local error="$2"
  local bold_red_text='\e[91m'
  local reset_text='\033[0m'

  echo -e "$bold_red_text|___ $message$reset_text"
  echo -e "     $error"
}

__process_msg "adding dns settings to the node"
exec_cmd "echo 'supersede domain-name-servers 8.8.8.8, 8.8.4.4;' >> /etc/dhcp/dhclient.conf"

__process_msg "adding auth_no_challenge to ~/.wgetrc"
touch ~/.wgetrc
echo "auth_no_challenge = on" > ~/.wgetrc

__process_msg "downloading node scripts tarball"
exec_cmd "wget '$NODE_TARBALL_URL' -O $NODE_SCRIPTS_DOWNLOAD_LOCATION"

__process_msg "creating node scripts dir"
exec_cmd "mkdir -p $NODE_SCRIPTS_LOCATION"

__process_msg "extracting node scripts"
exec_cmd "tar -xzvf '$NODE_SCRIPTS_DOWNLOAD_LOCATION' \
  -C $NODE_SCRIPTS_LOCATION \
  --strip-components=1"

__process_msg "Initializing node"
source "$NODE_SCRIPTS_LOCATION/initScripts/$ARCHITECTURE/$OS/$INIT_SCRIPT_NAME"

__process_msg "removing ~/.wgetrc"
rm -rf ~/.wgetrc
