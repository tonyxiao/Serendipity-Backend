describe 'ExpirationService', () ->
  myId = null
  connectedUserId = null

  beforeAll () ->
    ExpirationService.get().pause()

  beforeEach () ->
    Users.remove({})
    Connections.remove({})

    myId = insertVettedUser()
    connectedUserId = insertVettedUser()

  describe 'expireConnections', () ->
    it 'should expire non-ketchy users', () ->
      connectionId = insertUnexpiredConnection(myId, connectedUserId, new Date(0))
      new ExpirationService().expireConnections(new Date(500))
      connection = Connections.findOne connectionId
      expect(connection.expired).toEqual(true)

    it 'should not expire users when timestamp is greater than current date', () ->
      connectionId = insertUnexpiredConnection(myId, connectedUserId, new Date(1000))
      new ExpirationService().expireConnections(new Date(500))
      connection = Connections.findOne connectionId
      expect(connection.expired).toEqual(false)

    it 'should not expire ketchy connections', () ->
      Meteor.settings.crabUserId = connectedUserId
      connectionId = insertUnexpiredConnection(myId, connectedUserId, new Date(0))
      new ExpirationService().expireConnections(new Date(500))
      connection = Connections.findOne connectionId
      expect(connection.expired).toEqual(false)