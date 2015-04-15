
Template.renderConnectionUser.helpers
  dereferenceUser: (connectionUser) ->
    Users.findOne connectionUser._id

# TODO: consolidate dereferenceUser method
Template.connectionUserActions.helpers
  dereferenceUser: (connectionUser) ->
    Users.findOne connectionUser._id

Template.connectionDetails.helpers
  readableType: ->
    if @type == 'yes'
      return 'marry'
    if @type == 'maybe'
      return 'keep'
    return ''

  expirationStatus: ->
    if @_id?
      if @isExpired()
        return 'expired'
      else
        return 'not expired'

Template.connectionUserActions.helpers
  lastMessageTextSeen: ->
    if @lastMessageIdSeen? and Messages.findOne(@lastMessageIdSeen)?
      Messages.findOne(@lastMessageIdSeen).text

Template.connectionUserActions.events
  'click .send-message': (event) ->
    textField = $(event.target).prev('.message-text')
    text = textField.val()
    connectionId = $(event.target).closest('.connection-details').data('connection-id')
    Meteor.call 'connection/sendMessageAs', connectionId, @_id, text
    textField.val('') # Clear text field

  'click .mark-as-read': (event) ->
    connectionId = $(event.target).closest('.connection-details').data('connection-id')
    Meteor.call 'connection/markAsReadFor', connectionId, @_id

Template.connectionDetails.events
  'click .set-expire-days': ->
    days = parseFloat $('#expire-days').val()
    Meteor.call 'connection/setExpireDays', @_id, days
