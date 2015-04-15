logger = new KetchLogger 'api'

# TODO: Make sure only authenticated users can call these methods

Meteor.methods
  'user/addPushToken': (appid, apnEnvironment, pushToken) ->
    Meteor.user().addDevice
      _id: pushToken
      appId: appid
      apnEnvironment: apnEnvironment
      pushToken: pushToken
      updatedAt: new Date

  'user/delete': ->
    user = Meteor.user()
    if user?
      user.markAsDeleted()
    else
      error = new Meteor.Error(500, 'Can only call delete when user is logged in')
      logger.error(error)
      throw error

  'user/report': (userIdToReport, reason) ->
    logger.info 'user reporting not implemented'

  'candidate/submitChoices': (choices) ->
    # TODO: Add validation for input params
    result = _.object _.map choices, (candidateId, choice) ->
      candidate = Candidates.findOne candidateId
      connectionId = candidate.makeChoice choice
      return if connectionId? then [choice, connectionId] else []

    Meteor.user().populateCandidateQueue 3

    return result

  'user/update/birthday': (month, day) ->
    Meteor.user().updateBirthday(month, day)

  'connection/sendMessage': (connectionId, text) ->
    # TODO: Add validation for input params
    connection = Connections.findOne connectionId
    if connection?
      connection.createNewMessage text, Meteor.user()

  'connection/markAsRead': (connectionId) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.markAsReadFor Meteor.user()