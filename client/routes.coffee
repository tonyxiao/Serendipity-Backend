
Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  @render 'userDetails', data: Users.findOne(@.params._id)

# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'
