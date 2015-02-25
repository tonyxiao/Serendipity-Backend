# TODO: What's the difference between npm.require vs meteor.npmRequire
apn = Meteor.npmRequire 'apn'
path = Npm.require 'path'

# TODO: Make this work for multiple apnEnvironments
apnConnection = new apn.Connection
  cert: path.join process.env.PWD, 'credentials', 'ketch_apns_sandbox.pem'
  key: path.join process.env.PWD, 'credentials', 'milasya_apns.pem'
  passphrase: process.env.APNS_KEY_PASSPHRASE
  production: false

class @PushService

  @sendTestMessage: (pushToken, message) ->
    note = new apn.Notification
    note.expiry = Math.floor(Date.now() / 1000) + 3600 # expires 1 hour from now
    note.alert = message
    device = new apn.Device pushToken
    apnConnection.pushNotification note, device
