yaml = Npm.require('yamljs')
env = if process.env.env? then process.env.env else 'local'

console.log "Resolved environment to '#{env}'"

allSettings = yaml.parse Assets.getText 'settings.yml'
Meteor.settings = allSettings[env]

