Router.route '/', ->
  # render the Home template with a custom data context
  @render 'home'
