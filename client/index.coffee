# TODO: Remove DEBUG ONLY subscription
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'
Meteor.subscribe 'metadata'
Meteor.subscribe 'settings'
Meteor.subscribe 'allDevices'

## Client side collections
@Metadata = new Mongo.Collection 'metadata'
@Settings = new Mongo.Collection 'settings'

## Routing
Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userDetails', data: user

Router.route '/users/:_id/candidates', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userCandidates', data: user

Router.route '/users/:_id/previous_candidates', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userPreviousCandidates', data: user

Router.route '/users/:_id/connections', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userConnections', data: user

Router.route '/connections/:_id', ->
  connection = Connections.findOne @params._id
  @render 'connectionDetails', data: connection

Router.route '/import', ->
  @render 'importFixture'

Router.route '/vet', ->
  @render 'vetQueue'

Router.route '/data', ->
  @render 'dataPatch'

Router.route '/support', ->
  @render 'support'

Router.route '/users/:_id/edit', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userEdit', data: user

# Catch all route to splash screen
Router.route '/(.*)', ->
  @render 'splash'

## Global Template Helpers

Template.registerHelper 'CurrentDate', ->
  new Date

Template.registerHelper 'loggedInUser', ->
  Meteor.user()

## Import Event Handling

Template.importFixture.helpers
  oneMinuteFromNow: ->
    now = new Date
    return now.getTime() + 1 * 60000

Template.importFixture.events
  'click .remove-all-fake-data': ->
    if confirm ("sure?")
      Meteor.call 'admin/clearFakeUsers'

  'click .remove-next-refresh': ->
    if confirm("sure?")
      refreshTime = parseInt($("#next-refresh-textbox").val())
      Meteor.call 'admin/globallySetNextRefresh', refreshTime

  'click .import-submit': ->
    Meteor.call 'admin/importFakeUsers'
