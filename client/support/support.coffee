
Template.support.helpers
  getCrabFromConnnection: ->
    return @.cachedCrabUser

  getUserFromConnection: ->
    return @.cachedNonCrabUser

  active: ->
    crabUser = Settings.findOne("crabUserId")
    if crabUser?
      crabUserId = crabUser.value
      selector = 'users._id': crabUserId

      return Connections.find(selector).fetch()
        .map (connection) ->
          nonCrabUser = []
          crabUser = connection.users.filter (user) ->
            if user._id != crabUserId
              nonCrabUser.push(user)
              return false
            return true

          if crabUser.length == 1 and nonCrabUser.length == 1 and crabUser[0].hasUnreadMessage
            connection.cachedCrabUser = crabUser[0] # cache crab user
            connection.cachedNonCrabUser = nonCrabUser[0] # cache non-crab user
            return connection
        .filter (connection) ->
          return connection?