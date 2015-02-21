
Router.route 'users', ->
  @render 'userlist'

# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'
