
# TODO(qimingfang): remove this. it is used during development for debugging

# Allow all updates to users
Meteor.users.allow
  insert: ->
    true
  update: ->
    true
  remove: ->
  true

# Publish all documents
Meteor.publish 'allUsers', ->
  Users.find()

Meteor.publish 'allCandidates', ->
  Candidates.find()

Meteor.publish 'allConnections', ->
  Connections.find()

Meteor.publish 'allMessages', ->
  Messages.find()
