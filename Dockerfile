FROM lholota/bash-git

# Github labels
LABEL "com.github.actions.name"="dokku-pr-action"
LABEL "com.github.actions.description"="Deploy PR to Dokku"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/abulte/dokku-pr-action"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="Alexandre Bulté"

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
