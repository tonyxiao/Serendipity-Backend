createTestUser = (username, email, password) ->
  user = Meteor.users.findOne
    username: username
  if !user?
    Accounts.createUser
      username: username
      email: email
      password: password
      profile: {}
  user._id

describe "Connection", ->
  myId = ''
  myName = 'test-user'
  myEmail = 'test-user@foo.com'
  myPassword = 'test-password'

  matchId = ''
  matchName = "match-user"
  matchEmail = "match-email@foo.com"
  matchPassword = "match-password"

  beforeAll (done) ->
    myId = createTestUser myName, myEmail, myPassword
    matchId = createTestUser matchName, matchEmail, matchPassword

    Meteor.loginWithPassword 'test-user@foo.com','test', done

  describe "sendMessage", ->
    connectionId = 0
    beforeEach (done) ->
      Meteor.call "clearMessages", (error) ->
        Meteor.call "clearConnections", (error) ->
          connectionId = Connections.insert
            users: [
              {_id: myId, hasUnreadMessage: false}
              {_id: matchId, hasUnreadMessage: false}
            ]
            expiresAt: Connections.nextExpirationDate new Date
            type: "yes"
          done()

    it "should append a message to the connection", (done) ->
      Meteor.call "connection/sendMessage", connectionId, "potatoes", (error) ->
        console.log(Messages.find().fetch())
        matcher = Messages.find
          senderId : myId
          recipientId : matchId
          connectionId : connectionId
        messages = matcher.fetch()

        expect(messages.length).toBe(1)
        expect(messages[0].text).toBe("potatoes")
        done()

    it "should update the connection text to most recent message text", (done) ->
      Meteor.call "connection/sendMessage", connectionId, "cucumbers", (error) ->
        connection = Connections.findOne connectionId
        expect(connection.lastMessageText).toBe("cucumbers")
        done()