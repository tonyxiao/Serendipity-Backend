describe 'Match Service', () ->
  beforeEach () ->
    Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = 1
    Meteor.settings.REFRESH_INTERVAL_MILLIS = 3333

  describe 'refreshCandidate', () ->
    messages = {}

    insertVettedCandidate = (forUserId) ->
      userId = Users.insert
        nextRefreshTimestamp: new Date(1000)
        vetted: "yes"
      return Candidates.insert
        forUserId: forUserId
        userId: userId
        vetted: true
        active: false

    insertActiveCandidate = (forUserId) ->
      candidateId = insertVettedCandidate(forUserId)
      Candidates.findOne(candidateId).activate()

    createMockDevice = (id) ->
      return Devices.insert
        _id: id
        pushToken: id
        apsEnv: id
        appId: id

    createMockUserWithDevice = (id) ->
      deviceId = createMockDevice(id)

      return Users.insert
        nextRefreshTimestamp: new Date(1000)
        devices: [deviceId]
        vetted: "yes"

    beforeEach () ->
      Users.remove({})
      Messages.remove({})
      Candidates.remove({})

      # Mock the sendTestMessage method to cache sent messages in local dictionary.
      PushService.sendTestMessage = (pushToken, apsEnv, appId, message) ->
        messages[pushToken] = message

    it 'should correctly refresh candidates if vetted candidates exist', () ->
      mockUserId = createMockUserWithDevice('token_1')

      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      console.log 'should correctly refresh candidates if vetted candidates exist'
      new MatchService().refreshCandidate(mockUser, new Date(2000))

      expect(messages['token_1']).toEqual("Your Ketch has arrived!")
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      # Candidates are now active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not refresh candidates if not the right time', () ->
      mockUserId = createMockUserWithDevice('token_2')
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(0))

      # no messages were sent
      expect(messages['token_2']).toBeUndefined()
      # time should not update
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(1000)

      # Candidates are not active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(false)

    it 'should not refresh candidates if too many active candidates', () ->
      mockUserId = createMockUserWithDevice('token_3')
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(2000))

      # no messages were sent
      expect(messages['token_3']).toBeUndefined()
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      # Candidates are active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not activate too many candidates', () ->
      mockUserId = createMockUserWithDevice('token_4')
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(2000))

      mockDevice = Devices.find().fetch()[0]
      expect(messages['token_4']).toEqual("Your Ketch has arrived!")
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      numActiveCandidates = 0
      Candidates.find().fetch().forEach (candidate) ->
        numActiveCandidates += candidate.active ? 1 : 0

      expect(numActiveCandidates).toEqual(3)