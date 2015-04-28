describe 'Match Service', () ->

  beforeEach () ->
    Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = 1
    Meteor.settings.REFRESH_INTERVAL_MILLIS = 3333

  describe 'refreshCandidate', () ->
    mockUserId = null
    mockDevice = null

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

    beforeEach () ->
      Users.remove({})
      Messages.remove({})
      Candidates.remove({})

      mockDevice = {
        messages: []
        sendMessage: (message) ->
          @messages.push(message)
      }

      mockDevicesCursor = {
        fetch: () ->
          return [mockDevice]
      }

      Devices.find = (options) ->
        return mockDevicesCursor

      mockUserId = Users.insert
        nextRefreshTimestamp: new Date(1000)
        vetted: "yes"

    it 'should correctly refresh candidates if vetted candidates exist', () ->
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(2000))
      expect(mockDevice.messages.length).toEqual(1)
      expect(mockDevice.messages[0]).toEqual("Your Ketch has arrived!")
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      # Candidates are now active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not refresh candidates if not the right time', () ->
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(0))
      expect(mockDevice.messages.length).toEqual(0)
      # time should not update
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(1000)

      # Candidates are not active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(false)

    it 'should not refresh candidates if too many active candidates', () ->
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)
      insertActiveCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(2000))

      # no messages were sent
      expect(mockDevice.messages.length).toEqual(0)
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      # Candidates are active
      Candidates.find().fetch().forEach (candidate) ->
        expect(candidate.active).toEqual(true)

    it 'should not activate too many candidates', () ->
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)
      insertVettedCandidate(mockUserId)

      mockUser = Users.findOne mockUserId
      new MatchService().refreshCandidate(mockUser, new Date(2000))
      expect(mockDevice.messages.length).toEqual(1)
      expect(mockDevice.messages[0]).toEqual("Your Ketch has arrived!")
      # time incremented by REFRESH_INTERVAL_MILLIS
      expect(mockUser.nextRefreshTimestamp.getTime()).toEqual(4333)

      numActiveCandidates = 0
      Candidates.find().fetch().forEach (candidate) ->
        numActiveCandidates += candidate.active ? 1 : 0

      expect(numActiveCandidates).toEqual(3)