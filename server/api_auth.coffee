logger = Meteor.npmRequire('bunyan').createLogger name: 'auth'



# TODO: Do we need Meteor.startup here?
Meteor.startup ->

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
      height: FixtureService.randomHeight() # TODO: omit height
    }

    if FixtureService.mostRecentSchool(userInfo.education)?
      info.education = FixtureService.mostRecentSchool(userInfo.education).school.name

    if FixtureService.mostRecentJob(userInfo.work)?
      work = FixtureService.mostRecentJob(userInfo.work)
      info.work = work.employer.name

    if userInfo.birthday?
      info.birthday = userInfo.birthday
      info.age = FixtureService.age(userInfo.birthday)

    if userInfo.gender?
      info.gender = userInfo.gender

    if userInfo.bio?
      info.about = userInfo.bio

    if userInfo.location?
      # TODO: consider deriving location from GPS instead.
      info.location = userInfo.location.name

    Users.update user._id,
      $set: info

    # Update user photos if need be
    if not user.photoUrls?
      user.reloadPhotosFromFacebook()

    # a newly registered user will have no matches, let's give him / her some love
    if user.candidateQueue().count() < 3
      user.populateCandidateQueue 12

    return userId: user._id
