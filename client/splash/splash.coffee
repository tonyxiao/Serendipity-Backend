Template.splash.helpers
  version: ->
    return Metadata.findOne("softMinBuild").value + " | " + Metadata.findOne("hardMinBuild").value