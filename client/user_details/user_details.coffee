
Template.userDetails.events
  'click .update-fb-access-token': ->
    accessToken = $('#fb-access-token').val()
    Users.update @_id, $set: 'services.facebook.accessToken': accessToken

  'click .login-as-user': ->
    if confirm('sure?')
      accessToken = $('#fb-access-token').val()
      loginRequest = {
        accessToken: accessToken
        expiresAt: new Date() + 3 * 86400000 # 3 days from now
      }

      Accounts.callLoginMethod {
        methodArguments: [{ "fb-access": loginRequest }]
      }

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
    textarea = $('#push-token textarea')
    Meteor.call 'admin/user/addPushToken', @_id, textarea.val()
    textarea.val('')

  'click .send-push-message': ->
    textarea = $('#push-message textarea')
    Meteor.call 'admin/user/sendPushMessage', @_id, textarea.val()
    textarea.val('')