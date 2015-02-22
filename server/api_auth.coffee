logger = Meteor.npmRequire('bunyan').createLogger name: 'auth'

# TODO: Do we need Meteor.startup here?
Meteor.startup ->

  # Login handler for FB
  Accounts.registerLoginHandler 'fb-access', (serviceData) ->
    loginRequest = serviceData['fb-access']
    accessToken = loginRequest.accessToken
    userInfo = Meteor.http.call('GET', 'https://graph.facebook.com/me?access_token=#{accessToken}').data
    userInfo.accessToken = accessToken
    userInfo.expireAt = loginRequest.expire_at
    
    accountInfo = Accounts.updateOrCreateUserFromExternalService 'facebook', userInfo, {}
    user = Users.findOne(accountInfo.userId)
    Users.update user._id,
      $set:
        firstName: userInfo.first_name
        about: userInfo.first_name
        education: 'Harvard'
        age: 23
        location: 'mountain view, ca'
        work: 'google'

    # Update user photos if need be
    if user.photoUrls?
      user.reloadPhotosFromFacebook()

    # a newly registered user will have no matches, let's give him / her some love
    if user.candidateQueue().count() < 3
      user.populateCandidateQueue 12

    return user._id
