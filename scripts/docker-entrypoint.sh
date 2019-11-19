#!/bin/bash
# Solves permission problems with the mounted mauidata directory and allows
# running Tomcat as nonroot.
# See https://denibertovic.com/posts/handling-permissions-with-docker-volumes/

MY_UID=${MY_UID:-0}
MY_GID=${MY_GID:-0}

echo "Starting with UID $MY_UID and GID $MY_GID"
groupadd -r $MY_UID -g $MY_GID
useradd --shell /bin/bash -u $MY_UID -g $MY_GID -o -c "" -m tomcat_user

chown -R $MY_UID:$MY_GID /usr/local/tomcat
chown -R $MY_UID:$MY_GID /mauidata

exec gosu tomcat_user "$@"
