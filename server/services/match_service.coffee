logger = new KetchLogger 'match_service'

class @MatchService
  constructor: ->
    @paused = false

  isPaused: ->
    @paused

  pause: ->
    @paused = true

  unpause: ->
    @paused = false

  refreshCandidate: (user, currentDate) ->
    if !user.nextRefreshTimestamp?
      user.nextRefreshTimestamp = currentDate

    # send you new matches if you've waited for long enough
    if currentDate >= user.nextRefreshTimestamp
      numAllowedActiveUsers = Meteor.settings.numAllowedActiveGames *
        Candidates.NUM_CANDIDATES_PER_GAME

      activeCandidates = user.activeCandidates().fetch()
      numUsersToBeActivated = numAllowedActiveUsers - activeCandidates.length

      # if we can still activate more users, activate more users.
      if numUsersToBeActivated > 0
        user.vettedNotActiveCandidates().fetch().forEach (candidate) ->
          if numUsersToBeActivated == 0
            return

          numUsersToBeActivated--
          candidate.activate()
        user.sendNotification "Your Ketch has arrived!"

      # update the next refresh timestamp regardless
      user.updateNextRefreshTimestamp()

  refreshCandidates: (currentDate) ->
    self = this

    users = Users.find({
      vetted: 'yes'
    }).fetch()

    users.forEach (user) ->
      self.refreshCandidate(user, currentDate)

  @getMatchService: ->
    if @instance?
      return @instance

    @instance = new MatchService()
    return @instance

  # TOOD: Make user part of constructor
  @generateMatchesForUser: (user, maxCount) ->
    maxCount ?= 12 # Default to 12 max
    # current candidates should not be surfaced in the match queue.
    ineligibleUserIds = _.map user.allCandidates().fetch(), (candidate) -> candidate.userId

    # connections should never be surfaced in the match queue
    user.allConnections().fetch().forEach (connection) ->
      otherUserId = connection.otherUserId(user)
      if otherUserId?
        ineligibleUserIds.push otherUserId
      else
        logger.error("user.allConnections returned collection #{connection._id} which does not contain the user in context (#{user._id})")

    ineligibleUserIds.push user._id
    ineligibleUserIds.push Meteor.settings.crabUserId

    # TODO: Randomize & take into account gender, machine learning, what have you
    matchedUsers = Users.find({
      _id: $nin: ineligibleUserIds
      vetted: "yes"
      status: $ne: "deleted"
    }, {
      limit: maxCount
      fields: _id: 1
    }).fetch()

    for matchedUser in matchedUsers
      user.addUserAsCandidate matchedUser._id


@matchService = MatchService.getMatchService()
Meteor.setInterval ->
  if (!matchService.paused)
    matchService.refreshCandidates new Date
, 1000