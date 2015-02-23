
class @MatchService

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
      user.addUserAsCandidate matchedUser
