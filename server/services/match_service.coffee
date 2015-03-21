
class @MatchService

  constructor: ->
    @paused = false

  isPaused: ->
    @paused

  pause: ->
    @paused = true

  unpause: ->
    @paused = false

  refreshCandidates: (currentDate) ->
    users = Users.find({
      vetted: "yes"
    }).fetch()

    users.forEach (user) ->
      if !user.nextRefreshTimestamp?
        user.nextRefreshTimestamp = currentDate

      # send you new matches if you've waited for long enough
      if currentDate >= user.nextRefreshTimestamp
        numAllowedActiveUsers = Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES *
          Candidates.NUM_CANDIDATES_PER_GAME

        activeCandidates = user.activeCandidates().fetch()

        # new game happened
        if activeCandidates.length < numAllowedActiveUsers
          vettedCandidates = user.vettedCandidates(
            Meteor.settings.numAllowedActiveGames - activeCandidates.length)
          vettedCandidates.forEach (candidate) ->
            candidate.activate()

          user.sendTestPushMessage "Your Ketch has arrived!"

        user.updateNextRefreshTimestamp()

  @getMatchService: ->
    if @instance?
      return @instance

    @instance = new MatchService()
    return @instance

  # TOOD: Make user part of constructor
  @generateMatchesForUser: (user, maxCount) ->
    maxCount ?= 12 # Default to 12 max
    ineligibleUserIds = _.map user.allCandidates().fetch(), (candidate) -> candidate.userId
    ineligibleUserIds.push user._id

    # TODO: Randomize & take into account gender, machine learning, what have you
    matchedUsers = Users.find({
      _id: $nin: ineligibleUserIds
      vetted: "yes"
    }, {
      limit: maxCount
      fields: _id: 1
    }).fetch()

    for matchedUser in matchedUsers
      user.addUserAsCandidate matchedUser._id


matchService = MatchService.getMatchService()
Meteor.setInterval ->
  if (!matchService.paused)
    matchService.refreshCandidates new Date
, 1000