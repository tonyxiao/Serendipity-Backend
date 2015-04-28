Template.vetUser.events
  'click .vet-user': ->
    if confirm('sure?')
      Meteor.call 'admin/user/vet', @_id

Template.blockUser.events
  'click .block-user': ->
    if confirm('sure?')
      Meteor.call 'admin/user/blockFromKetch', @_id

Template.snoozeUser.events
  'click .snooze-user': ->
    if confirm('sure?')
      Meteor.call 'admin/user/snooze', @_id