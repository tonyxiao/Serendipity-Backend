
class @DataPatch
  @connectionsWithInvalidUsers: ->
    invalidConnections = []
    connections = Connections.find().fetch()
    connections.forEach (connection) ->
      done = false
      connection.users.forEach (user) ->
        if !Users.findOne(user._id)? && !done
          invalidConnections.push(connection)
          done = true
    return invalidConnections

  @candidatesWithInvalidUsers: ->
    invalidCandidates = []
    Candidates.find().fetch().forEach (candidate) ->
      if !Users.findOne(candidate.forUserId)? || !Users.findOne(candidate.userId)?
        invalidCandidates.push(candidate)
    return invalidCandidates

Template.dataPatch.helpers
  connectionsWithInvalidUsers: ->
    DataPatch.connectionsWithInvalidUsers()

  candidatesWithInvalidUsers: ->
    DataPatch.candidatesWithInvalidUsers()

  candidateForUserName: (candidate) ->
    user = Users.findOne(candidate.forUserId)
    if user?
      return user.firstName
    else
      return "???"

  candidateToUserName: (candidate) ->
    user = Users.findOne(candidate.userId)
    if user?
      return user.firstName
    else
      return "???"

  usersWithInvalidProfiles: ->
    invalidUsers = []
    Users.find().fetch().forEach (user) ->
      if !Match.test(user, UserSchema)
        invalidUsers.push(user)
    return invalidUsers

Template.dataPatch.events
  'click .remove-candidates-with-invalid-users': ->
    DataPatch.candidatesWithInvalidUsers().forEach (candidate) ->
      Meteor.call 'candidate/remove', candidate._id
  'click .remove-connections-with-invalid-users': ->
    DataPatch.connectionsWithInvalidUsers().forEach (connection) ->
      Meteor.call 'connection/remove', connection._id
