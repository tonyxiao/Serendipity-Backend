
Meteor.startup ->

  ServiceConfiguration.configurations.upsert { service: "facebook" },
    $set:
      appId: Meteor.settings.facebook.appId
      secret: Meteor.settings.facebook.secret
      loginStyle: "popup"

  ServiceConfiguration.configurations.upsert { service: "google" },
    $set:
      clientId: Meteor.settings.google.clientId
      secret: Meteor.settings.google.secret
      loginStyle: "popup"

