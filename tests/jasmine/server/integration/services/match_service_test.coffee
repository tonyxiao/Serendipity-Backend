describe 'Match Service', () ->

  beforeEach () ->
    # clear users
    Users.remove({})
    Meteor.settings.NUM_ALLOWED_ACTIVE_GAMES = 1

  it 'should correctly refresh candidates if vetted candidates exist', () ->
    insertVettedCandidate = (forUserId) ->
      userId = Users.insert
        nextRefreshTimestamp: new Date(1000)
        vetted: "yes"
      Candidates.insert
        forUserId: forUserId
        userId: userId
        vetted: true
        active: false

    mockUserId = Users.insert
      nextRefreshTimestamp: new Date(1000)
      vetted: "yes"
    insertVettedCandidate(mockUserId)
    insertVettedCandidate(mockUserId)
    insertVettedCandidate(mockUserId)

    mockUser = Users.findOne mockUserId
    spyOn(mockUser, 'sendNotification')

    new MatchService().refreshCandidate(mockUser, new Date(2000))
    expect(mockUser.sendNotification).toHaveBeenCalled()
