#!/bin/sh

echo "-----> METEOR_SETTINGS resolved to -> $ENV"

GULP=node_modules/gulp/bin/gulp.js

cd .scripts
npm install --production
$GULP settings
export METEOR_SETTINGS=$(cat ../settings.json)

