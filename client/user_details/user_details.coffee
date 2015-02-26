
Template.userDetails.events
  'click .update-fb-access-token': ->
    accessToken = $('#fb-access-token').val()
    Users.update @_id, $set: 'services.facebook.accessToken': accessToken

  'click .clear-photos': ->
    if confirm('sure?')
      Meteor.call 'user/clearPhotos', @_id

  'click .reload-fb-photos': ->
    if confirm('sure?')
     Meteor.call 'user/reloadPhotosFromFacebook', @_id

  'click .remove-device': (event) ->
    userId = $(event.target).closest('.user-details').data('user-id')
    Meteor.call 'admin/user/removePushToken', userId, @_id

  'click .add-push-token': ->
    pushToken = $('#push-token textarea').val()
    Meteor.call 'admin/user/addPushToken', @_id, pushToken
    $('#push-token').val('')

  'click .send-push-message': ->
    pushMessage = $('#push-message textarea').val()
    Meteor.call 'admin/user/sendPushMessage', @_id, pushMessage
    $('#push-message').val('')