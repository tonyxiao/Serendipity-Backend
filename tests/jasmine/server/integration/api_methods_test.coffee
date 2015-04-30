# Mock of npm 'request'
class FakeRequest
  constructor: () ->
    @url = null
    @json = null
  post: (url) ->
    self = this
    @url = url
    return {
      json: (json) ->
        self.json = json
    }

describe 'Api Methods', () ->
  mockUser = null

  ######################
  ### Connection API ###
  ######################
  describe 'Connection', () ->
    senderId = null
    recipientId = null
    connectionId = null
    messageId = null

    beforeEach () ->
      Users.remove({})
      Connections.remove({})
      Messages.remove({})

      senderId = insertVettedUser()
      recipientId = insertVettedUser()

      users = []
      users.push { _id: senderId, hasUnreadMessage: true }
      users.push { _id: recipientId, hasUnreadMessage: true }

      # insert a test connection

      connectionId = Connections.insert
        users: users
        expiresAt: new Date
        expired: false
        type: 'yes'

      # insert a test message, sent by mockRecipient, to test that lastMessageIdSeen
      # updates correctly.
      messageId = Messages.insert
        connectionId: connectionId
        senderId: recipientId
        recipientId: senderId
        text: 'message1'

    it 'connection/markAsRead should mark hasUnreadMessage', () ->
      sender = Users.findOne senderId
      recipient = Users.findOne recipientId

      # senders is logged in
      Meteor.user = () ->
        return Users.findOne senderId

      Meteor.call 'connection/markAsRead', connectionId, (err, res) ->
        connection = Connections.findOne connectionId
        senderInfo = connection.getUserInfo sender
        recipientInfo = connection.getUserInfo recipient
        expect(senderInfo.hasUnreadMessage).toBe(false)
        expect(recipientInfo.hasUnreadMessage).toBe(true)
        expect(senderInfo.lastMessageIdSeen).toBe(messageId)

    it 'connection/sendMessage should insert a new message', () ->
      # sender is logged in
      Meteor.user = () ->
        return Users.findOne senderId

      Meteor.call 'connection/sendMessage', connectionId, 'hello', (err, res) ->
        connection = Connections.findOne connectionId
        expect(connection.lastMessageText).toEqual('hello')

        message = Messages.findOne
          senderId: senderId
          recipientId: recipientId
        expect(message.text).toEqual('hello')
        expect(message.connectionId).toEqual(connectionId)

    it 'connection/sendMessage should send a slack notification if recipient is crab', () ->
      fakeRequest = new FakeRequest()

      spyOn(Meteor, 'npmRequire').and.returnValue(fakeRequest)

      # sender is logged in
      Meteor.user = () ->
        return Users.findOne senderId

      # sender is sending to crab
      Meteor.settings.crabUserId = recipientId

      Meteor.call 'connection/sendMessage', connectionId, 'hello', (err, res) ->
        connection = Connections.findOne connectionId
        expect(connection.lastMessageText).toEqual('hello')

        message = Messages.findOne
          senderId: senderId
          recipientId: recipientId
        expect(message.text).toEqual('hello')
        expect(message.connectionId).toEqual(connectionId)
        expect(fakeRequest.url).toEqual(Meteor.settings.slack.url)
        expect(fakeRequest.json.channel).toEqual('#ketchy')

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
        expect(candidate.choice).toEqual('yes')
        expect(me.candidateQueueSize).toEqual(3)

  ###################
  ### Devices API ###
  ###################
  describe 'Devices', () ->
    deviceOptions = null
    pushOptions = null
    currentUserId = null

    verifyDevice = (deviceDetails) ->
      device = Devices.findOne deviceDetails._id
      delete device['updatedAt']
      delete device['createdAt']
      delete device['updatedBy']

      _.each deviceDetails, (value, key) ->
        expect(deviceDetails[key]).toEqual(device[key])

    beforeEach () ->
      # clear dbs
      Devices.remove({})
      Users.remove({})

      deviceOptions = { '_id' : 'deviceId' }
      pushOptions = { 'pushToken' : 'token' }

      currentUserId = Users.insert
        firstName : 'testUser'

      # clear the session
      SessionData.set('default_connection_id', undefined)

      # user is not logged in by default
      Meteor.user = () ->
        return undefined

    it 'connectDevice should store device with user if user is logged in', () ->
      # user is logged in
      Meteor.user = () ->
        return Users.findOne currentUserId
      Meteor.call 'connectDevice', 'deviceId', deviceOptions, (err, res) ->
        expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_ID))
            .toEqual('deviceId')
        expect(Meteor.user().device_ids).toEqual(['deviceId'])
        verifyDevice(deviceOptions)

    it 'connectDevice should store device in session if user is not logged in', () ->
      Meteor.call 'connectDevice', 'deviceId', deviceOptions, (err, res) ->
        expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_ID))
            .toEqual('deviceId')
        verifyDevice(deviceOptions)

    it 'device/update/push should store info with device if user logged in', () ->
      # user is logged in
      Meteor.user = () ->
        return Users.findOne currentUserId

      SessionData.update('default_connection_id', ACTIVE_DEVICE_ID, 'testDeviceId')

      Meteor.call 'device/update/push', pushOptions, (err, res) ->
        expectedDeviceDetails = {
          _id: 'testDeviceId'
          pushToken: 'token'
        }

        expect(Meteor.user().device_ids).toEqual(['testDeviceId'])
        expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_DETAILS))
            .toEqual(expectedDeviceDetails)
        verifyDevice(expectedDeviceDetails)

    it 'device/update/push should store info in session if user is not logged in', () ->
      SessionData.update('default_connection_id', ACTIVE_DEVICE_ID, 'testDeviceId')
      Meteor.call 'device/update/push', pushOptions, (err, res) ->
        expectedDeviceDetails = {
          _id: 'testDeviceId'
          pushToken: 'token'
        }

        expect(SessionData.getFromConnection("default_connection_id", ACTIVE_DEVICE_DETAILS))
            .toEqual(expectedDeviceDetails)
        verifyDevice(expectedDeviceDetails)

