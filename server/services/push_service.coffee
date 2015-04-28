logger = new KetchLogger 'push-service'

# TODO: What's the difference between npm.require vs meteor.npmRequire
apn = Meteor.npmRequire 'apn'
path = Npm.require 'path'

devApnConnection = new apn.Connection
  cert: path.join process.env.PWD, 'server/private', 'apns_sandbox-com.milasya.ketch.dev.cert.pem'
  key: path.join process.env.PWD, 'server/private', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.apns.keyPassphrase
  production: false

betaApnConnection = new apn.Connection
  cert: path.join process.env.PWD, 'server/private', 'apns_prod-com.milasya.ketch.beta.cert.pem'
  key: path.join process.env.PWD, 'server/private', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.apns.keyPassphrase
  production: true

prodApnConnection = new apn.Connection
  cert: path.join process.env.PWD, 'server/private', 'apns_prod-com.milasya.ketch.cert.pem'
  key: path.join process.env.PWD, 'server/private', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.apns.keyPassphrase
  production: true

class @PushService

  @sendTestMessage: (pushToken, apnEnvironment, appId, message) ->
    note = new apn.Notification
    note.expiry = Math.floor(Date.now() / 1000) + 3600 # expires 1 hour from now
    note.alert = message
    note.badge = 1
    note.sound = 'default'
    device = new apn.Device pushToken

    apnConnection = null

    if apnEnvironment == 'production' && appId == 'com.milasya.ketch'
      apnConnection = prodApnConnection
    else if apnEnvironment == 'production' && appId == 'com.milasya.ketch.beta'
      apnConnection = betaApnConnection
    else if apnEnvironment == 'development' && appId == 'com.milasya.ketch.dev'
      apnConnection = devApnConnection

    if apnConnection == null
      logger.info "No ApnConnection found for environment #{apnEnvironment} and appId #{appId}"
    else
      apnConnection.pushNotification note, device
