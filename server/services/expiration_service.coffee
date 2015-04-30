
class @ExpirationService

  constructor:  ->
    @paused = false

  pause: ->
    @paused = true

  unpause: ->
    @paused = false

  @get: ->
    if @instance?
      return @instance

    @instance = new ExpirationService()
    return @instance

  expireConnections: (currentDate) ->
    if !@paused
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
  ExpirationService.get().expireConnections new Date
, 1000