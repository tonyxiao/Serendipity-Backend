
Meteor.methods
  chooseYesNoMaybe: (yesId, noId, maybeId) ->
    yesCandidate = Candiates.findOne yesId
    noCandidate = Candiates.findOne noId
    maybeCandidate = Candiates.findOne maybeId

    yesCandidate .makeChoice 'yes'
    noCandidate .makeChoice 'no'
    maybeCandidate .makeChoice 'maybe'

    result = {}
    for candidate in [yesCandidate , maybeCandidate]
      if candidate.matchesWithInverse()
        result[candidate.choice] = candidate.forUser().connectWithUser candidate.user()

    Meteor.user().populateCandidateQueue 3

    return result

  'connection/sendMessage': (connectionId, text) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.createNewMessage text, Meteor.user()