
class @MatchService

  @refreshCandidates: (currentDate) ->
    users = Users.find().fetch()

    users.forEach (user) ->
      if !user.nextRefreshTimestamp?
        user.nextRefreshTimestamp = currentDate

      # send you new matches if you've waited for long enough
      if currentDate >= user.nextRefreshTimestamp
        numAllowedActiveGames =
          (Meteor.settings && Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES) or 1
        numAllowedActiveUsers = numAllowedActiveGames * Candidates.NUM_CANDIDATES_PER_GAME

        activeCandidates = user.activeCandidates().fetch()
        if activeCandidates.length < numAllowedActiveUsers
          vettedCandidates = user.getVettedCandidates(
            numAllowedActiveGames - activeCandidates.length)
          vettedCandidates.forEach (candidate) ->
            candidate.activate()

        user.updateNextRefreshTimestamp()

  # TOOD: Make user part of constructor
  @generateMatchesForUser: (user, maxCount) ->
    maxCount ?= 12 # Default to 12 max
    ineligibleUserIds = _.map user.allCandidates().fetch(), (candidate) -> candidate.userId
    ineligibleUserIds.push user._id

    # TODO: Randomize & take into account gender, machine learning, what have you
    matchedUsers = Users.find({
      _id: $nin: ineligibleUserIds
    }, {
      limit: maxCount
      fields: _id: 1
    }).fetch()

    for matchedUser in matchedUsers
      user.addUserAsCandidate matchedUser._id

Meteor.setInterval ->
  MatchService.refreshCandidates new Date
, 1000