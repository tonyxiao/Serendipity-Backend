Template.userEdit.helpers
  info: ->
    view = @
    delete view.services
    delete view._id
    delete view.createdAt
    delete view.updatedAt
    delete view.devices
    delete view.nextRefreshTimestamp

    return JSON.stringify(view);

Template.userEdit.events
  'click .edit-submit': ->
    updatedInfo = $("#json-text").val()
    userId = $(event.target).closest('.import').data('user-id')
    Meteor.call('admin/user/edit', userId, updatedInfo)