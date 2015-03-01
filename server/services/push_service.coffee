# TODO: What's the difference between npm.require vs meteor.npmRequire
apn = Meteor.npmRequire 'apn'
path = Npm.require 'path'

# TODO: Make this work for multiple apnEnvironments
apnConnection = new apn.Connection
  cert: path.join Meteor.settings.PWD, 'credentials', 'apns_sandbox-com.milasya.ketch.dev.cert.pem'
  key: path.join Meteor.settings.PWD, 'credentials', 'milasya_apns.key.pem'
  passphrase: Meteor.settings.APNS_KEY_PASSPHRASE
  production: false

class @PushService

  @sendTestMessage: (pushToken, message) ->
    note = new apn.Notification
    note.expiry = Math.floor(Date.now() / 1000) + 3600 # expires 1 hour from now
    note.alert = message
    device = new apn.Device pushToken
    apnConnection.pushNotification note, device
