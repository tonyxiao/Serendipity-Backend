#!/bin/sh

echo "-----> METEOR_SETTINGS resolved to -> $ENV"

# TODO: Move logic into custom meteor buildpack
# This type of script really belongs in the buildpack so that when we
# scale the server it doesn't need to be launched with every new instance

# Generate settings.json file
GULP=node_modules/gulp/bin/gulp.js

cd .scripts
npm install --production
$GULP settings

# Go back to original directory, and set METEOR_SETTINGS
cd ..
export METEOR_SETTINGS=$(cat ../settings.json)

