# TODO: Account service seems to be in order
Accounts.config
  forbidClientAccountCreation: true
  loginExpirationInDays: null # Logins on client should be basically permanent
#  restrictCreationByEmailDomain: 'milasya.com'


# TODO: Avoid issues with load order timing by moving schema and collection definition into libs
Meteor.users.helpers
  isAdmin: ->
    Roles.userIsInRole(@, 'admin')

  promoteAdmin: ->
    Roles.addUsersToRoles(@, 'admin')

  demoteAdmin: ->
    Roles.removeUsersFromRoles(@, 'admin')
