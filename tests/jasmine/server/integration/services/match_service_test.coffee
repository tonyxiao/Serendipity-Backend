# TODO: Make this a custom matcher
Meteor.users.helpers
  hasUserAsCandidate: (user) ->
    (_.find @allCandidates().fetch(), (candidate) -> candidate.userId == user._id)?

# Tests
describe 'Match Service', () ->
  beforeAll ->
    matchService.pause()

  beforeEach ->
    Users.remove {}
    Messages.remove {}
    Candidates.remove {}
    Devices.remove {}

  describe 'refreshCandidate', () ->
    messages = {}

    beforeAll ->
      Meteor.settings.numAllowedActiveGames = 1

    beforeEach ->
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

  describe 'matchUsers', ->
    it 'should match based on gender', ->
      straightGuy = Users.findOne createMockUserWithDevice('token_1', 'male', 'women')
      straightGirl = Users.findOne createMockUserWithDevice('token_2', 'female', 'men')
      gayGuy = Users.findOne createMockUserWithDevice('token_3', 'male', 'men')
      lesbianGirl = Users.findOne createMockUserWithDevice('token_4', 'female', 'women')
      lesbianGirl2 = Users.findOne createMockUserWithDevice('token_44', 'female', 'women')
      biGirl = Users.findOne createMockUserWithDevice('token_5', 'female', 'both')
      biGuy = Users.findOne createMockUserWithDevice('token_6', 'male', 'both')

      for user in [straightGuy, straightGirl, gayGuy, lesbianGirl, lesbianGirl2, biGuy, biGirl]
        MatchService.generateMatchesForUser user

      # TODO: Make this a custom matcher so result output is much more userful
      expect(straightGuy.hasUserAsCandidate(straightGirl)).toBe(true)
      expect(straightGuy.hasUserAsCandidate(biGirl)).toBe(true)
      expect(straightGuy.hasUserAsCandidate(lesbianGirl)).toBe(false)
      expect(straightGuy.hasUserAsCandidate(gayGuy)).toBe(false)
      expect(straightGuy.hasUserAsCandidate(biGuy)).toBe(false)

      expect(straightGirl.hasUserAsCandidate(straightGuy)).toBe(true)
      expect(straightGirl.hasUserAsCandidate(biGirl)).toBe(false)
      expect(straightGirl.hasUserAsCandidate(lesbianGirl)).toBe(false)
      expect(straightGirl.hasUserAsCandidate(gayGuy)).toBe(false)
      expect(straightGirl.hasUserAsCandidate(biGuy)).toBe(true)

      expect(lesbianGirl.hasUserAsCandidate(lesbianGirl2)).toBe(true)
      expect(biGuy.hasUserAsCandidate(biGirl)).toBe(true)

