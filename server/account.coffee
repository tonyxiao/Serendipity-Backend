logger = Meteor.npmRequire('bunyan').createLogger name: 'account'
graph = Meteor.npmRequire('fbgraph')

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
    Users.update { _id: meteorId.userId },
      $set:
        firstName: userInfo.first_name
        about: userInfo.first_name
        education: 'Harvard'
        age: 23
        location: 'mountain view, ca'
        work: 'google'

    user = Users.findOne(accountInfo.userId)
    graph.setAccessToken currentUser.services.facebook.accessToken

    fbGetFn = Meteor.wrapAsync(graph.get)

    # Update user photos
    if user.photoUrls?
      photoUrls = getUserPhotos(fbGetFn, user)
      Users.update user._id, $set: photos: photoUrls

      # a newly registered user will have no matches, let's give him / her some love
      user.populateCandidateQueue 12

    return user._id
