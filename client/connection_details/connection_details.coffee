
Template.connectionDetails.helpers
  readableType: ->
    if @type == 'yes'
      return 'marry'
    if @type == 'maybe'
      return 'keep'
    return ''

  expirationStatus: ->
    if @isExpired() then 'expired' else 'not expired'

  dereferenceUser: (connectionUser) ->
    Users.findOne connectionUser._id

Template.connectionDetails.events
  'click .send-message': (event) ->
    textField = $(event.target).prev('.message-text')
    text = textField.val()
    connectionId = $(event.target).closest('.connection-details').data('connection-id')
    Meteor.call 'connection/sendMessageAs', connectionId, @_id, text
    textField.val('') # Clear text field

  'click .set-expire-days': ->
    days = parseFloat $('#expire-days').val()
    Meteor.call 'connection/setExpireDays', @_id, days

  'click .mark-as-read': (event) ->
    connectionId = $(event.target).closest('.connection-details').data('connection-id')
    Meteor.call 'connection/markAsReadFor', connectionId, @_id
