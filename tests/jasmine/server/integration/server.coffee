# For some reason the DB does not get cleared after each test is run
# Tried enabling client-side removal of {@code Message} and {@code Connection}
# instances, but that also didn't work.
# TODO: to remove this hack
Meteor.methods
  'clearMessages': ->
    Messages.remove({})
  'clearConnections': ->
    Connections.remove({})


Meteor.startup ->
  console.log "Server started"
