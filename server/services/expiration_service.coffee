
class @ExpirationService

  @expireConnections: (currentDate) ->
    Connections.update {
      $and: [
        { 'users._id': {$ne : Meteor.settings.crabUserId }} # connections to crab don't expire
        { expired: $ne: true }
        { expiresAt: $lte: currentDate }
      ]
    }, {
      $set:
        expired: true
    }

Meteor.setInterval ->
  ExpirationService.expireConnections new Date
, 1000