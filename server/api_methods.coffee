logger = new KetchLogger 'api'

# TODO: Make sure only authenticated users can call these methods

class @DeviceRegistrationService
  # Registers the device with the current user, if the current user is known
  # If the current user is not known, register it into the session
  @registerDevice: (deviceId, currentUser, options) ->
    if deviceId?
      options['_id'] = deviceId
      options = DeviceRegistrationService.update(options)
      if currentUser?
        currentUser.upsertDevice(options)
    else
      error = new Meteor.Error(500, "Registering a device with no id. #{currentUser._id} | #{options}")
      logger.error(error)
      throw error

  @update: (options) ->
    details = ServerSession.get(ACTIVE_DEVICE_DETAILS)
    if !details?
      details = {}

    _.extend details, options

    ServerSession.set(ACTIVE_DEVICE_DETAILS, details)
    return details

Meteor.methods
  # Account settings updates
  'me/update/birthday': (month, day) ->
    Meteor.user().updateBirthday(month, day)

  'me/update/genderPref': (genderPref) ->
    Meteor.user().updateAttribute('genderPref', genderPref)

  'me/update/height': (height) ->
    Meteor.user().updateAttribute('height', height)

  'me/update/work': (work) ->
    Meteor.user().updateAttribute('work', work)

  'me/update/education': (education) ->
    Meteor.user().updateAttribute('education', education)

  'me/update/about': (about) ->
    Meteor.user().updateAttribute('about', about)

  # Device updates
  'device/update/location': (locationOptions) ->
    logger.info "Adding location info #{JSON.stringify(locationOptions)}"
    deviceId = ServerSession.get(ACTIVE_DEVICE_ID)
    DeviceRegistrationService.registerDevice(deviceId, Meteor.user(), locationOptions)

  'device/update/push': (pushOptions) ->
    logger.info "Adding push token info #{JSON.stringify(pushOptions)}"
    deviceId = ServerSession.get(ACTIVE_DEVICE_ID)
    DeviceRegistrationService.registerDevice(deviceId, Meteor.user(), pushOptions)

  # global
  'connectDevice': (deviceId, options) ->
    logger.info "Connecting device #{deviceId} with options #{JSON.stringify(options)}"
    ServerSession.set(ACTIVE_DEVICE_ID, deviceId)
    DeviceRegistrationService.registerDevice(deviceId, Meteor.user(), options)

  'deleteAccount': ->
    user = Meteor.user()
    if user?
      user.markAsDeleted()
      user.logout()

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

  'user/report': (userIdToReport, reason) ->
    logger.info 'user reporting not implemented'

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