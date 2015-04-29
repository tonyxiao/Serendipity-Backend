describe 'Match Service', () ->
  beforeAll () ->
    matchService.pause()

  beforeEach () ->
    Meteor.settings.numAllowedActiveGames = 1

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
        nextRefreshTimestamp: new Date(1)
        device_ids: [deviceId]
        vetted: "yes"

    beforeEach () ->
      Users.remove({})
      Messages.remove({})
      Candidates.remove({})

      # Mock the sendTestMessage method to cache sent messages in local dictionary.
      PushService.sendTestMessage = (pushToken, apsEnv, appId, message) ->
        messages[pushToken] = message

    it 'should correctly refresh candidates if vetted candidates exist', () ->
      now = new Date(2) # now > nextRefreshTimestamp
      mockUserId = createMockUserWithDevice('token_1')

      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, now)

      expect(messages['token_1']).toEqual("Your Ketch has arrived!")
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(84813000)

      # Candidates are now active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not refresh candidates if not the right time', () ->
      now = new Date(0) # now < nextRefreshTimestamp
      mockUserId = createMockUserWithDevice('token_2')
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, now)

      # no messages were sent
      expect(messages['token_2']).toBeUndefined()
      # time should not update
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(1)

      # Candidates are not active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(false)

    it 'should not refresh candidates if too many active candidates', () ->
      now = new Date(2) # now > nextRefreshTimestamp
      mockUserId = createMockUserWithDevice('token_3')
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, now)

      # no messages were sent
      expect(messages['token_3']).toBeUndefined()
      # apr 29, 15:33:33 PDT
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(84813000)

      # Candidates are active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not activate too many candidates', () ->
      now = new Date(2) # now > nextRefreshTimestamp
      mockUserId = createMockUserWithDevice('token_4')
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, now)

      expect(messages['token_4']).toEqual("Your Ketch has arrived!")
      # apr 29, 15:33:33 PDT
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(84813000)

      numActiveCandidates = 0
      Candidates.find().fetch().forEach (candidate) ->
        numActiveCandidates += candidate.active ? 1 : 0

      expect(numActiveCandidates).toEqual(3)