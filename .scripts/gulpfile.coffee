gulp = require 'gulp'
yaml = require 'gulp-yaml'
jsonEditor = require 'gulp-json-editor'

gulp.task 'settings', ->
  env = if process.env.ENV then process.env.ENV else 'local'
  console.log "Will output settings for environment = #{env}"
  gulp.src 'settings.yml'
    .pipe yaml()
    .pipe jsonEditor (json) ->
      json[env]
    .pipe gulp.dest '../'
