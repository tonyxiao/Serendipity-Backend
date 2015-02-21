
Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  @render 'userDetails', data: Users.findOne(@.params._id)

Router.route '/users/:_id/candidates', ->
  @render 'userCandidates', data: Users.findOne(@.params._id)

Router.route '/users/:_id/connections', ->
  @render 'userConnections', data: Users.findOne(@.params._id)

# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'
