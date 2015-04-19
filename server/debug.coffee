
# TODO(qimingfang): remove this. it is used during development for debugging

# Allow all updates to users
Meteor.users.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
    true

Meteor.startup ->
  Accounts.registerLoginHandler 'debug', (serviceData) ->
    if !serviceData['debug']?
      return undefined

    if serviceData.debug.userId?
      user = Users.findOne(serviceData.debug.userId)
      if user?
        return userId: user._id

    throw Meteor.Error(400, "Trying to log in with fake user #{serviceData} failed")

# Publish all documents
Meteor.publish 'allUsers', ->
  Users.find()

Meteor.publish 'allCandidates', ->
  Candidates.find()

Meteor.publish 'allConnections', ->
  Connections.find()

Meteor.publish 'allMessages', ->
  Messages.find()
