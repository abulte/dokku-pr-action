 #!/usr/bin/env bash
set -e

echo "Triggered by: $GITHUB_EVENT_ACTION"
echo "Linked service: $LINKED_SERVICE"

echo "Setting up SSH directory"
SSH_PATH="$HOME/.ssh"
mkdir -p "$SSH_PATH"
chmod 700 "$SSH_PATH"

echo "Saving SSH key"
echo "$PRIVATE_KEY" > "$SSH_PATH/deploy_key"
chmod 600 "$SSH_PATH/deploy_key"

GIT_SSH_COMMAND="ssh -p ${PORT-22} -i $SSH_PATH/deploy_key"
if [ -n "$HOST_KEY" ]; then
    echo "Adding hosts key to known_hosts"
    echo "$HOST_KEY" >> "$SSH_PATH/known_hosts"
    chmod 600 "$SSH_PATH/known_hosts"
else
    echo "Disabling host key checking"
    GIT_SSH_COMMAND="$GIT_SSH_COMMAND -o StrictHostKeyChecking=no"
fi

REF=$(echo $GITHUB_REF | sed -e 's/\//-/g')
APP_NAME="$PROJECT-$REF"

# CAVEAT: synchronized is also triggered when reopened
# if some commits have been made in the meantime :-(
if [ "$GITHUB_EVENT_ACTION" = "opened" ] || [ "$GITHUB_EVENT_ACTION" = "reopened" ]
then
    echo "Creating app $APP_NAME"
    # create app
    $GIT_SSH_COMMAND dokku@$HOST "apps:create $APP_NAME" || true
    # create linked service
    if [ -n "$LINKED_SERVICE" ]
    then
        echo "Creating linked service"
        $GIT_SSH_COMMAND dokku@$HOST "$LINKED_SERVICE:create $APP_NAME"
        $GIT_SSH_COMMAND dokku@$HOST "$LINKED_SERVICE:link $APP_NAME $APP_NAME"
    fi
fi

if [ "$GITHUB_EVENT_ACTION" = "closed" ]
then
    echo "Deleting app $APP_NAME"
    # delete app and exit
    # --force requires dokku>=0.21.3
    $GIT_SSH_COMMAND dokku@$HOST "apps:destroy --force $APP_NAME"
    if [ -n "$LINKED_SERVICE" ]
    then
        echo "Removing linked service"
        # <<< $APP_NAME is used to confirm, --force is not supported here
        $GIT_SSH_COMMAND dokku@$HOST "$LINKED_SERVICE:destroy $APP_NAME" <<< $APP_NAME
    fi
    exit 0
fi

if [ -f ".env.dokku-pr" ]
then
    echo "Setting config variables from .env.dokku-pr"
    DOKKU_CONFIG=$(tr '\n' ' ' < .env.dokku-pr)
    $GIT_SSH_COMMAND dokku@$HOST "config:set --no-restart $APP_NAME $DOKKU_CONFIG"
fi

echo "The deploy is starting"

GIT_COMMAND="git push --force dokku@$HOST:$APP_NAME HEAD:refs/heads/master"

echo "GIT_SSH_COMMAND="$GIT_SSH_COMMAND" $GIT_COMMAND"
GIT_SSH_COMMAND="$GIT_SSH_COMMAND" $GIT_COMMAND

URL="https://$APP_NAME.$HOST"
echo "::set-output name=url::$URL"

if [ "$GITHUB_EVENT_ACTION" = "opened" ] || [ "$GITHUB_EVENT_ACTION" = "reopened" ]
then
    # enable ssl
    # CAVEAT won't return fail status code if error occurs
    echo "Allowing SSL on $APP_NAME"
    $GIT_SSH_COMMAND dokku@$HOST "letsencrypt $APP_NAME"
fi
