logger = new KetchLogger 'api'

# TODO: Make sure only authenticated users can call these methods

class @DeviceRegistrationService
  # Registers the device with the current user, if the current user is known
  # If the current user is not known, register it into the session
  @registerDevice: (deviceId, options, connectionId) ->
    if deviceId?
      options['_id'] = deviceId

    options = DeviceRegistrationService.update(options, connectionId)
    
    if deviceId?
      Devices.update deviceId, {
        $set: options
      },  upsert: true

      if Meteor.user()?
        Meteor.user().addDevice deviceId

  @update: (options, connectionId) ->
    details = SessionData.getFromConnection(connectionId, ACTIVE_DEVICE_DETAILS)
    if !details?
      details = {}

    _.extend details, options

    SessionData.update(connectionId, ACTIVE_DEVICE_DETAILS, details)
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
    deviceId = SessionData.getFromConnection(this.connection.id, ACTIVE_DEVICE_ID)
    DeviceRegistrationService.registerDevice(deviceId, locationOptions, this.connection.id)

  'device/update/push': (pushOptions) ->
    logger.info "Adding push token info #{JSON.stringify(pushOptions)}"

    # TODO: this is here to enable testing, because I can't figure out how to mock
    # this.connection. Refactor this into a connectionid utility that can be mocked.
    connectionId = "default_connection_id"
    if this.connection?
      connectionId = this.connection.id

    deviceId = SessionData.getFromConnection(connectionId, ACTIVE_DEVICE_ID)
    DeviceRegistrationService.registerDevice(deviceId, pushOptions, connectionId)

  # global
  'connectDevice': (deviceId, options) ->
    logger.info "Connecting device #{deviceId} with options #{JSON.stringify(options)}"

    # TODO: this is here to enable testing, because I can't figure out how to mock
    # this.connection. Refactor this into a connectionid utility that can be mocked.
    connectionId = "default_connection_id"
    if this.connection?
      connectionId = this.connection.id
    SessionData.update(connectionId, ACTIVE_DEVICE_ID, deviceId)
    DeviceRegistrationService.registerDevice(deviceId, options, connectionId)

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