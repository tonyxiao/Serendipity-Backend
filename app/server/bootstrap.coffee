
Meteor.startup ->

  ServiceConfiguration.configurations.upsert { service: "facebook" },
    $set:
      appId: Meteor.settings.FB_APPID
      secret: Meteor.settings.FB_APP_SECRET
      loginStyle: "popup"

  ServiceConfiguration.configurations.upsert { service: "google" },
    $set:
      clientId: Meteor.settings.GOOGLE_CLIENT_ID
      secret: Meteor.settings.GOOGLE_CLIENT_SECRET
      loginStyle: "popup"

