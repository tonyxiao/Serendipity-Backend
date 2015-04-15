logger = new KetchLogger 'auth'

# TODO: Do we need Meteor.startup here?
Meteor.startup ->

  crab = Users.findOne(Meteor.settings.CRAB_USER_ID)
  if !crab?
    error = new Meteor.Error(500, 'Exception: Crab user not found! This means that users will not be able to chat with support!');
    logger.error(error)
    throw error

  # Login handler for FB
  Accounts.registerLoginHandler 'fb-access', (serviceData) ->
    loginRequest = serviceData['fb-access']
    accessToken = loginRequest.accessToken
    userInfo = Meteor.http.call('GET', "https://graph.facebook.com/me?access_token=#{accessToken}").data

    userInfo.accessToken = accessToken
    userInfo.expireAt = loginRequest.expire_at
    
    accountInfo = Accounts.updateOrCreateUserFromExternalService 'facebook', userInfo, {}
    user = Users.findOne(accountInfo.userId)

    info = {
      firstName: userInfo.first_name
      lastName: userInfo.last_name
      height: FixtureService.randomHeight() # TODO: omit height
    }

    if FixtureService.mostRecentSchool(userInfo.education)?
      info.education = FixtureService.mostRecentSchool(userInfo.education).school.name

    if FixtureService.mostRecentJob(userInfo.work)?
      work = FixtureService.mostRecentJob(userInfo.work)
      info.work = work.employer.name

    if userInfo.birthday?
      info.birthday = new Date userInfo.birthday
      info.age = FixtureService.age(userInfo.birthday)

    if userInfo.gender?
      info.gender = userInfo.gender

    if userInfo.bio?
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
        { 'users._id' : Meteor.settings.CRAB_USER_ID }
        { 'users._id' : user._id}
      ]

    if connectionToCrab.fetch().length == 0
      connectionId = user.connectWithUser(Meteor.settings.CRAB_USER_ID, "yes")

      # in an ideal world, this would be 'never', but since we are forced to add an
      # expiration timestamp to our data model, set this to far far into the future.
      crabExpiresAt = new Date Meteor.settings.CRAB_EXPIRATION_DATE_MILLIS

      logger.info "updated #{connectionId} with #{crabExpiresAt}"

      Connections.update connectionId,
        $set:
          expiresAt: crabExpiresAt



    # Update user photos if need be
    if !user.photoUrls?
      user.reloadPhotosFromFacebook()

    return userId: user._id
