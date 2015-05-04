logger = new KetchLogger 'auth'
analytics.load Meteor.settings.segmentWriteKey

Accounts.config
  forbidClientAccountCreation: true
  loginExpirationInDays: null # Logins on client should be basically permanent
#  restrictCreationByEmailDomain: 'milasya.com'


# TODO: Do we need Meteor.startup here?
Meteor.startup ->

  crab = Users.findOne(Meteor.settings.crabUserId)
  if !crab?
    error = new Meteor.Error(500, 'Exception: Crab user not found! This means that users will not be able to chat with support!');
#    logger.error(error)

  if !Meteor.settings.segmentWriteKey?
    error = new Meteor.Error(500, 'SEGMENT_WRITE_KEY not defined! Analytics will not be captured');
#    logger.error(error)

  # Login handler for FB
  Accounts.registerLoginHandler 'fb-access', (serviceData) ->
    loginRequest = serviceData['fb-access']
    if !loginRequest?
      return undefined

    accessToken = loginRequest.accessToken
    userInfo = Meteor.http.call('GET', "https://graph.facebook.com/me?access_token=#{accessToken}").data

    userInfo.accessToken = accessToken
    userInfo.expireAt = loginRequest.expire_at

    existingUser = Users.findOne
      'services.facebook.id': userInfo.id

    accountInfo = Accounts.updateOrCreateUserFromExternalService 'facebook', userInfo, {}
    user = Users.findOne(accountInfo.userId)

    if user._isDeleted()
      # TODO: if a user was marked as deleted, Account.updateOrCreateUserFromExternalService
      # should have returned a new user. For now, simply prevet the user from logging in.
      error =  new Meteor.Error(501, "Logging in with deleted user #{accountInfo.userId}")
      logger.error(error)
      throw error

    # Ketchy crab should not get any info pulled from Facebook.
    if user._id == Meteor.settings.crabUserId
      return userId: user._id

    info = {
      firstName: userInfo.first_name
      lastName: userInfo.last_name
    }

    if userInfo.gender?
      info.gender = userInfo.gender

    if userInfo.email?
      info.email = userInfo.email

    # do not overwrite editable info if the user already had it saved.
    if FixtureService.mostRecentSchool(userInfo.education)? and !user.education?
      info.education = FixtureService.mostRecentSchool(userInfo.education).school.name

    if FixtureService.mostRecentJob(userInfo.work)? and !user.work?
      work = FixtureService.mostRecentJob(userInfo.work)
      info.work = work.employer.name

    if userInfo.birthday? and !user.birthday? and !user.age?
      info.birthday = new Date userInfo.birthday
      info.age = FixtureService.age(userInfo.birthday)

    if userInfo.bio? and !user.about?
      info.about = userInfo.bio

    if userInfo.location?
      # TODO: consider deriving location from GPS instead.
      info.location = userInfo.location.name

    # TODO: don't assume that the user is in Pacific time zone
    # TODO: handle timezone changes
    info.timezone = 'America/Los_Angeles'

    # TODO: consider using simpleschema autovalue:
    # https://github.com/aldeed/meteor-collection2/blob/master/README.md#attaching-a-schema-to-a-collection
    if !user.vetted?
      info.vetted = 'snoozed'

    if !user.metadata?
      info.metadata = {}

    Users.update user._id,
      $set: info

    # For first time users, establish connection with crab
    connectionToCrab = Connections.find
      $and: [
        { 'users._id' : Meteor.settings.crabUserId }
        { 'users._id' : user._id}
      ]

    if connectionToCrab.fetch().length == 0
      connectionId = user.connectWithUser(Meteor.settings.crabUserId, "yes")

      # in an ideal world, this would be 'never', but since we are forced to add an
      # expiration timestamp to our data model, set this to far far into the future.
      crabExpiresAt = new Date Meteor.settings.crabExpirationDateMillis
      Connections.update connectionId,
        $set:
          expiresAt: crabExpiresAt

      crabConnection = Connections.findOne connectionId

      crabConnection.messageWithoutPushNotification Meteor.settings.warmWelcomeText, crabConnection.otherUser(user)

    # if the user device registration info came before the user login info,
    # it would be stored in the cache. We should update the user's device info accordingly
    deviceId = SessionData.getFromConnection(this.connection.id, ACTIVE_DEVICE_ID)
    if deviceId?
      user.addDevice deviceId

    # Reload photos from facebook if the user did not have photos before.
    if !user.photos?
      user.reloadPhotosFromFacebook()

    # Identify this user to segment.io
    analytics.identify
      userId: user._id
      traits:
        firstName: info.firstName
        lastName: info.lastName
        email: info.email

    analytics.track
      userId: user._id
      event: 'login'

    if !existingUser?
      message = "<#{process.env.ROOT_URL}users/#{user._id}|#{info.firstName} #{info.lastName}> just signed up!"
      new SlackService('#growth', ':crabby:').send(message)

    return userId: user._id
