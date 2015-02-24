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
    Users.update user._id,
      $set:
        firstName: userInfo.first_name
        about: userInfo.first_name
        education: FixtureService.randomSchool()
        # TODO: Get data from facebook to actually populate
        # TODO: Age should be computed, not stored, also omit height
        age: FixtureService.randomAge()
        height: FixtureService.randomHeight()
        location: FixtureService.randomLocation()
        work: FixtureService.randomJob()
        gender: FixtureService.randomGender()

    # Update user photos if need be
    if not user.photoUrls?
      user.reloadPhotosFromFacebook()

    # a newly registered user will have no matches, let's give him / her some love
    if user.candidateQueue().count() < 3
      user.populateCandidateQueue 12

    return userId: user._id
