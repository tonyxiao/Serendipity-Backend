# TODO: Remove DEBUG ONLY subscription
Meteor.subscribe 'allUsers'
Meteor.subscribe 'allCandidates'
Meteor.subscribe 'allConnections'
Meteor.subscribe 'allMessages'
Meteor.subscribe 'metadata'

## Routing

Router.route '/users', ->
  @render 'userList'

Router.route '/users/:_id', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userDetails', data: user.adminView()

Router.route '/users/:_id/candidates', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userCandidates', data: user.adminView()

Router.route '/users/:_id/previous_candidates', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userPreviousCandidates', data: user.adminView()

Router.route '/users/:_id/connections', ->
  user = Users.findOne(@params._id)
  if user?
    @render 'userConnections', data: user.view()

Router.route '/connections/:_id', ->
  connection = Connections.findOne @params._id
  @render 'connectiondetails', data: connection

Router.route '/import', ->
  @render 'importFixture'

Router.route '/vet', ->
  @render 'vetQueue'

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
      _.each Users.find().fetch(), (u) ->
        if (u.services.tinder)
          console.log "will delete #{u._id} #{u.firstName}"
          Meteor.call 'admin/user/remove', u._id

  'click .remove-next-refresh': ->
    if confirm("sure?")
      refreshTime = parseInt($("#next-refresh-textbox").val())
      Meteor.call 'admin/globallySetNextRefresh', refreshTime

  'click .import-submit': ->
    jsonText = $('#json-text').val()
    $('#json-text').val('')
    Meteor.call 'import/tinder', jsonText, (err, res) ->
      alert unless err? then "imported #{res} users" else "#{err.reason}: #{err.details}"

