#!/bin/bash
set -e

echo "Setting up SSH directory"
SSH_PATH="$HOME/.ssh"
mkdir -p "$SSH_PATH"
chmod 700 "$SSH_PATH"

echo "Saving SSH key"
echo "$PRIVATE_KEY" > "$SSH_PATH/deploy_key"
chmod 600 "$SSH_PATH/deploy_key"

GIT_COMMAND="git push dokku@$HOST:$PROJECT HEAD:master"
if [ -n "$FORCE_DEPLOY" ]; then
    echo "Enabling force deploy"
    GIT_COMMAND="$GIT_COMMAND --force"
fi

GIT_SSH_COMMAND="ssh -p ${PORT-22} -i $SSH_PATH/deploy_key"
if [ -n "$HOST_KEY" ]; then
    echo "Adding hosts key to known_hosts"
    echo "$HOST_KEY" >> "$SSH_PATH/known_hosts"
    chmod 600 "$SSH_PATH/known_hosts"
else
    echo "Disabling host key checking"
    GIT_SSH_COMMAND="$GIT_SSH_COMMAND -o StrictHostKeyChecking=no"
fi

EXISTS_MSG=$($GIT_SSH_COMMAND dokku@$HOST apps:exists $PROJECT)

if [[ $EXISTS_MSG != *already* ]]; then
    echo "Creating the app"
    $GIT_SSH_COMMAND dokku@$HOST apps:create $PROJECT
fi

if [ -n "$APP_CONFIG" ]; then
    echo "Setting app config"
    $GIT_SSH_COMMAND dokku@$HOST config:set --no-restart $PROJECT $APP_CONFIG
fi

echo "The deploy is starting"
GIT_SSH_COMMAND="$GIT_SSH_COMMAND" $GIT_COMMAND
