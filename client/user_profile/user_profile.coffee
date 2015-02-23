
Template.userDetails.events
  'click .update-fb-access-token': ->
    accessToken = $('#fb-access-token').val()
    Users.update @_id, $set: 'services.facebook.accessToken': accessToken

  'click .clear-photos': ->
    Meteor.call 'user/clearPhotos', @_id

  'click .reload-fb-photos': ->
#    if confirm('sure?')
    Meteor.call 'user/reloadPhotosFromFacebook', @_id