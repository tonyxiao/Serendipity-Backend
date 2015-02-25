# TODO: Remove DEBUG ONLY subscription
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'

## Routing

Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  @render 'userDetails', data: Users.findOne @params._id

Router.route '/users/:_id/candidates', ->
  @render 'userCandidates', data: Users.findOne @params._id

Router.route '/users/:_id/previous_candidates', ->
  @render 'userPreviousCandidates', data: Users.findOne @params._id

Router.route '/users/:_id/connections', ->
  @render 'userConnections', data: Users.findOne @params._id

Router.route '/connections/:_id', ->
  connection = Connections.findOne @params._id
  @render 'connectionDetails', data: connection

Router.route '/import', ->
  @render 'importFixture'

# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'

## Global Template Helpers

Template.registerHelper 'CurrentDate', ->
  CurrentDate.get()

## Import Event Handling

Template.importFixture.events
  'click .import-submit': ->
    jsonText = $('#json-text').val()
    $('#json-text').val('')
    Meteor.call 'import/tinder', jsonText, (err, res) ->
      alert unless err? then "imported #{res} users" else "#{err.reason}: #{err.details}"

