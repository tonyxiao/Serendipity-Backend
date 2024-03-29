# WARNING: This file should be loaded before anything else in the app
# It might not be enough that it's located at server/lib/config.coffee
# Another file at server/lib/aaa.coffee will be loaded before this. Careful.

_.extend Meteor.settings,
  photoCountToDisplay: 3
  numAllowedActiveGames: 3
  defaultImageSize: 640
  crabUserId: 'ketchy' # TODO: remove this duplicate once we refactor
  crabFirstName: 'Ketchy'
  crabLastName: ''
  crabExpirationDateMillis: 5680281600000 # December 31, 2149
  warmWelcomeText: "Ahoy, Sailor! I'm Ketchy, your personal assistant. I'm here to answer questions and navigate you through an ocean of dating options. Please text or talk to me any time you need anything. I'm happy to help!"
  refreshIntervalMillis: 86400000 # 24 hours

# TODO: Convert env vars into settings at build time so settings.public
# can be sent down to javascript web clients
if !Meteor.settings.public?
  Meteor.settings.public = {}

_.extend Meteor.settings.public,
  softMinBuild: parseInt process.env.SOFT_MIN_BUILD or '0'
  hardMinBuild: parseInt process.env.HARD_MIN_BUILD or '0'
  edgePanEnabled: process.env.EDGE_PAN_ENABLED == 'true'
  crabUserId: Meteor.settings.crabUserId
 
