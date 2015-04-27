describe 'Api Methods', () ->
  mockUser = null

  ######################
  ### Connection API ###
  ######################
  describe 'Connection', () ->
    mockSender = {
      _id: 'mockSender'
      isVetted: () ->
        true
    }
    mockRecipient = {
      _id: 'mockRecipient'
      isVetted: () ->
        true
    }
    connectionId = null
    messageId = null

    beforeEach () ->
      users = []
      users.push { _id: mockSender._id, hasUnreadMessage: true }
      users.push { _id: mockRecipient._id, hasUnreadMessage: true }

      # insert a test connection
      Connections.remove({})
      connectionId = Connections.insert
        users: users
        expiresAt: new Date
        expired: false
        type: 'yes'

      # insert a test message, sent by mockRecipient, to test that lastMessageIdSeen
      # updates correctly.
      Messages.remove({})
      messageId = Messages.insert
        connectionId: connectionId
        senderId: mockRecipient._id
        recipientId: mockSender._id
        text: 'message1'

      spyOn(Users, 'findOne').and.callFake (userId) ->
        if userId == mockSender._id
          return mockSender
        return mockRecipient

    it 'connection/markAsRead should mark hasUnreadMessage', () ->
      # senders is logged in
      Meteor.user = () ->
        return mockSender

      Meteor.call 'connection/markAsRead', connectionId, (err, res) ->
        connection = Connections.findOne connectionId
        senderInfo = connection.getUserInfo mockSender
        recipientInfo = connection.getUserInfo mockRecipient
        expect(senderInfo.hasUnreadMessage).toBe(false)
        expect(recipientInfo.hasUnreadMessage).toBe(true)
        expect(senderInfo.lastMessageIdSeen).toBe(messageId)

    it 'connection/sendMessage should insert a new message', () ->
      # sender is logged in
      Meteor.user = () ->
        return mockSender

      Meteor.call 'connection/sendMessage', connectionId, 'hello', (err, res) ->
        connection = Connections.findOne connectionId
        expect(connection.lastMessageText).toEqual('hello')

        message = Messages.findOne
          senderId: mockSender._id
          recipientId: mockRecipient._id
        expect(message.text).toEqual('hello')
        expect(message.connectionId).toEqual(connectionId)

  #####################
  ### Candidate API ###
  #####################
  describe 'Candidates', () ->
    me = {
      _id: 'me'
      isVetted: () ->
        return true
      populateCandidateQueue: (num) ->
        @candidateQueueSize = num
    }
    candidateUser = {
      _id: 'candidate1',
      isVetted: () ->
        return true
    }
    candidateId = null
    beforeEach () ->
      Candidates.remove({})
      candidateId = Candidates.insert
        forUserId: me._id
        userId: candidateUser._id
        active: true
        vetted: true

      spyOn(Users, 'findOne').and.callFake (userId) ->
        if userId == me._id
          return me
        return candidateUser

    it 'candidate/submitChoices should save choice on candidates', () ->
      Meteor.user = () ->
        return me
      choice = {}
      choice['yes'] = candidateId
      Meteor.call 'candidate/submitChoices', choice, (err, res) ->
        candidate = Candidates.findOne candidateId
        console.log candidate
        expect(candidate.choice).toEqual('yes')
        expect(me.candidateQueueSize).toEqual(3)

  ###################
  ### Devices API ###
  ###################
  describe 'Devices', () ->
    deviceOptions = null
    pushOptions = null

    verifyDevice = (deviceDetails) ->
      device = Devices.findOne deviceDetails._id
      delete device['updatedAt']
      delete device['createdAt']
      delete device['updatedBy']

      _.each deviceDetails, (value, key) ->
        expect(deviceDetails[key]).toEqual(device[key])

    beforeEach () ->
      deviceOptions = { '_id' : 'deviceId' }
      pushOptions = { 'pushToken' : 'token' }

      mockUser = {
        _id: 'mockUserId',
        addDevice: (deviceId) ->
          if !@devices?
            @devices = []

          @devices.push deviceId
      }

      # clear devices
      Devices.remove({})

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

