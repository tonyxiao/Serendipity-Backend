# TODO: What's the difference between npm.require vs meteor.npmRequire
apn = Meteor.npmRequire 'apn'
path = Npm.require 'path'

devApnConnection = new apn.Connection
  cert: path.join Meteor.settings.PWD, 'credentials', 'apns_sandbox-com.milasya.ketch.dev.cert.pem'
  key: path.join Meteor.settings.PWD, 'credentials', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.APNS_KEY_PASSPHRASE
  production: false

betaApnConnection = new apn.Connection
  cert: path.join Meteor.settings.PWD, 'credentials', 'apns_prod-com.milasya.ketch.beta.cert.pem'
  key: path.join Meteor.settings.PWD, 'credentials', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.APNS_KEY_PASSPHRASE
  production: true

prodApnConnection = new apn.Connection
  cert: path.join Meteor.settings.PWD, 'credentials', 'apns_prod-com.milasya.ketch.cert.pem'
  key: path.join Meteor.settings.PWD, 'credentials', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.APNS_KEY_PASSPHRASE
  production: true

class @PushService

  @sendTestMessage: (pushToken, apnEnvironment, appId, message) ->
    note = new apn.Notification
    note.expiry = Math.floor(Date.now() / 1000) + 3600 # expires 1 hour from now
    note.alert = message
    device = new apn.Device pushToken

    apnConnection = null

    if apnEnvironment == "production" && appId == "com.milasya.ketch"
      apnConnection = prodApnConnection
    else if apnEnvironment == "production" && appId == "com.milasya.ketch.beta"
      apnConnection = betaApnConnection
    else if apnEnvironment == "development" && appId == "com.milasya.ketch.dev"
      apnConnection = devApnConnection

    if apnConnection == null
      console.log "No ApnConnection found for environment " + apnEnvironment + " and appId " + appId
    else
      apnConnection.pushNotification note, device
