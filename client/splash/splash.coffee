Template.splash.helpers
  version: ->
    return Version.findOne("softMinBuild").value + " | " + Version.findOne("hardMinBuild").value