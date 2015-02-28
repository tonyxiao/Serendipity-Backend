
class @ExpirationService

  @expireConnections: (currentDate) ->
    Connections.update {
        expired: $ne: true
        expiresAt: $lte: currentDate
      },
      $set:
        expired: true

Meteor.setInterval ->
  ExpirationService.expireConnections new Date
, 1000