this.SessionData = new ReactiveDict('ketch-server-session')

this.SessionData.getFromConnection = (connectionId, key) ->
  currentValues = SessionData.get(connectionId)
  if currentValues?
    return currentValues[key]

this.SessionData.update = (connectionId, key, value) ->
  currentValues = SessionData.get(connectionId)

  if !currentValues?
    currentValues = {}

  newValue = {}
  newValue[key] = value

  _.extend currentValues, newValue
  SessionData.set(connectionId, currentValues)


Meteor.onConnection (connection) ->
  SessionData.set(connection.id, {})

  connection.onClose () ->
    SessionData.set(connection.id, undefined)