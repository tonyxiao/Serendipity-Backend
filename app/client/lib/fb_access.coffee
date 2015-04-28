
# get the access token at start of page.
@loginWithFacebookAccess = ->
  permissions = [
    'email'
    'user_photos'
    'user_birthday'
    'user_education_history'
    'user_about_me'
    'user_work_history'
  ]

  accessToken = null

  ((d, debug) ->
    js = undefined
    id = 'facebook-jssdk'
    ref = d.getElementsByTagName('script')[0]
    if d.getElementById(id)
      return
    js = d.createElement('script')
    js.id = id
    js.async = true
    js.src = '//connect.facebook.net/en_US/all' + (if debug then '/debug' else '') + '.js'
    ref.parentNode.insertBefore js, ref
    return
  ) document, false

  window.fbAsyncInit = ->
  call_facebook_login = (response) ->
    loginRequest =
      accessToken: response.authResponse.accessToken
      expiresAt: new Date + 1000 * response.expiresIn
    Accounts.callLoginMethod methodArguments: [ { 'fb-access': loginRequest } ]
    return

  checkLoginStatus = (response) ->
    if response and response.status == 'connected'
      console.log 'User is authorized'
      call_facebook_login response
    else
      # Login the user
      FB.login ((response) ->
        if response.authResponse
          call_facebook_login response
        else
          console.log 'User cancelled login or did not fully authorize.'
        return
      ), scope: permissions.join()
    return

  Meteor.call 'getEnv', (err, env) ->
    # init the FB JS SDK
    FB.init
      appId: env.FB_APPID
      channelUrl: env.ROOT_URL + '/channel.html'
      status: true
      cookie: true
      xfbml: true
    FB.getLoginStatus checkLoginStatus
