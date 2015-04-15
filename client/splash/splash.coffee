Template.splash.helpers
  version: ->
    if Metadata.findOne("softMinBuild")? and Metadata.findOne("hardMinBuild")?
      return Metadata.findOne("softMinBuild").value + " | " + Metadata.findOne("hardMinBuild").value