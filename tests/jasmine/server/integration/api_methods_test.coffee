describe 'Device Operations', () ->
  mockUser = null
  deviceOptions = null
  pushOptions = null

  verifyDevice = (deviceDetails) ->
    device = Devices.findOne deviceDetails._id
    delete device['updatedAt']
    delete device['createdAt']
    delete device['updatedBy']

    expect(deviceDetails).toEqual(device)

  beforeEach () ->
    deviceOptions = { '_id' : 'deviceId' }
    pushOptions = { 'pushToken' : 'token' }

    mockUser = {
      _id: 'testing',
      addDevice: (deviceId) ->
        if !@devices?
          @devices = []

        @devices.push deviceId
    }

    # clear the session
    SessionData.set('default_connection_id', undefined)

    # user is not logged in by default
    Meteor.user = () ->
      return null

  it 'connectDevice should store device with user if user is logged in', () ->
    # user is logged in
    Meteor.user = () ->
      return mockUser
    Meteor.call 'connectDevice', 'deviceId', deviceOptions, (err, res) ->
      expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_ID))
          .toEqual('deviceId')
      expect(mockUser.devices).toEqual(['deviceId'])
      verifyDevice(deviceOptions)


  it 'connectDevice should store device in session if user is not logged in', () ->
    spyOn(mockUser, 'addDevice')
    Meteor.call 'connectDevice', 'deviceId', deviceOptions, (err, res) ->
      expect(mockUser.devices).toBeUndefined()
      expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_ID))
          .toEqual('deviceId')
      verifyDevice(deviceOptions)

  it 'device/update/push should store info with device if user logged in', () ->
    # user is logged in
    Meteor.user = () ->
      return mockUser

    SessionData.update('default_connection_id', ACTIVE_DEVICE_ID, 'testDeviceId')

    Meteor.call 'device/update/push', pushOptions, (err, res) ->
      expectedDeviceDetails = {
        _id: 'testDeviceId'
        pushToken: 'token'
      }

      expect(mockUser.devices).toEqual(['testDeviceId'])
      expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_DETAILS))
          .toEqual(expectedDeviceDetails)
      verifyDevice(expectedDeviceDetails)

  it 'device/update/push should store info in session if user is not logged in', () ->
    SessionData.update('default_connection_id', ACTIVE_DEVICE_ID, 'testDeviceId')
    spyOn(mockUser, 'addDevice')

    Meteor.call 'device/update/push', pushOptions, (err, res) ->
      expectedDeviceDetails = {
        _id: 'testDeviceId'
        pushToken: 'token'
      }

      expect(mockUser.devices).toBeUndefined()
      expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_DETAILS))
          .toEqual(expectedDeviceDetails)
      verifyDevice(expectedDeviceDetails)

