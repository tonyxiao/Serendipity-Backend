Template.userEdit.helpers
  info: ->
    view = @.view()
    delete view._id
    delete view.createdAt
    delete view.updatedAt
    delete view.devices
    delete view.nextRefreshTimestamp

    return JSON.stringify(view);