logger = new KetchLogger 'api'

# TODO: Make sure only authenticated users can call these methods

Meteor.methods

  # Account Updates
  'me/update/device': (device) ->
    user = Meteor.user()
    if user?
      user.addDevice
        _id: device.deviceId
        appId: device.appId
        apnEnvironment: device.apsEnv
        pushToken: device.pushToken
        updatedAt: new Date
    else
      logger.info "Tring to add device #{JSON.stringify(device)} for nonexistant user"

  'me/update/birthday': (month, day) ->
    Meteor.user().updateBirthday(month, day)

  'me/update/genderPref': (genderPref) ->
    Meteor.user().updateAttribute('genderPref', education)

  'me/update/height': (height) ->
    Meteor.user().updateAttribute('height', height)

  'me/update/work': (work) ->
    Meteor.user().updateAttribute('work', work)

  'me/update/education': (education) ->
    Meteor.user().updateAttribute('education', education)

  'me/update/about': (about) ->
    Meteor.user().updateAttribute('about', about)

  'me/delete': ->
    user = Meteor.user()
    if user?
      user.markAsDeleted()

  'user/report': (userIdToReport, reason) ->
    logger.info 'user reporting not implemented'


  # Core Mechanic
  'candidate/submitChoices': (choices) ->
    # TODO: Add validation for input params
    result = _.object _.map choices, (candidateId, choice) ->
      candidate = Candidates.findOne candidateId
      connectionId = candidate.makeChoice choice
      return if connectionId? then [choice, connectionId] else []

    Meteor.user().populateCandidateQueue 3

    return result

  'connection/sendMessage': (connectionId, text) ->
    # TODO: Add validation for input params
    connection = Connections.findOne connectionId
    if connection?
      connection.createNewMessage text, Meteor.user()

  'connection/markAsRead': (connectionId) ->
    connection = Connections.findOne connectionId
    if connection?
      connection.markAsReadFor Meteor.user()

  # Metadata operations
  # TODO: refactor
  '/metadata/insert': (metadata) ->
    logger.info "metadata insert #{JSON.stringify(metadata)}"
    user = Meteor.user()
    if user?
      modifier = {}
      modifier["metadata.#{metadata._id}"] = metadata.value
      Users.update user._id,
        $set: modifier

  '/metadata/remove': (metadata) ->
    logger.info "metadata remove #{JSON.stringify(metadata)}"
    user = Meteor.user()
    if user?
      modifier = {}
      modifier["metadata.#{metadata._id}"] = ""
      Users.update user._id,
        $unset: modifier

  '/metadata/update': (id, metadata) ->
    logger.info "metadata update #{JSON.stringify(id)} | #{JSON.stringify(metadata)}"

    user = Meteor.user()
    if user?
      modified = {}
      modified["metadata.#{id._id}"] = metadata['$set'].value

      modifier = {
        '$set': modified
      }

      Users.update user._id,
        modifier