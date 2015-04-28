#!/bin/sh

echo "-----> METEOR_SETTINGS resolved to -> $ENV"

npm install -g yamljs
export METEOR_SETTINGS=$(NODE_PATH=./.meteor/heroku_build/lib/node_modules/ \
                        node .scripts/resolve_settings.js $ENV)
