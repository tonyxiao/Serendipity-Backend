
Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  @render 'userDetails', data: Users.findOne @params._id

Router.route '/users/:_id/candidates', ->
  @render 'userCandidates', data: Users.findOne @params._id

Router.route '/users/:_id/connections', ->
  @render 'userConnections', data: Users.findOne @params._id

Router.route '/users/:_id/connections/:connectionId', ->
  user = Users.findOne @params._id
  connection = Connections.findOne @params.connectionId
  @render 'userConnectionDetails', data: {user: user, connection: connection}


# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'
