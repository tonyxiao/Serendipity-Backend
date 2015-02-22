
Meteor.methods
  chooseYesNoMaybe: (yesId, noId, maybeId) ->
    yesCandidate = Candiates.findOne yesId
    maybeCandidate = Candiates.findOne maybeId
    noCandidate = Candiates.findOne noId

    yesConnectionId = yesCandidate .makeChoice 'yes'
    maybeConnectionId = maybeCandidate .makeChoice 'maybe'
    noCandidate .makeChoice 'no'

    result = {}
    if yesConnectionId?
      result['yes'] = yesConnectionId
    if maybeConnectionId?
      result['maybe'] = maybeConnectionId

    Meteor.user().populateCandidateQueue 3

    return result

  'connection/sendMessage': (connectionId, text) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.createNewMessage text, Meteor.user()