logger = new KetchLogger 'candidates'

@Candidates = new Mongo.Collection 'candidates'
Candidates.attachBehaviour('timestampable')

# MARK: - Schema Validation
Candidates.attachSchema new SimpleSchema
  forUserId: type: String
  userId: type: String
  choice:
    type: String
    allowedValues: ['yes', 'no', 'maybe']
    optional: true
  vetted: type: Boolean
  active: type: Boolean

Candidates.NUM_CANDIDATES_PER_GAME =  3

# MARK: - Instance Methods
Candidates.helpers
  user: ->
    Users.findOne(@userId)

  forUser: ->
    Users.findOne(@forUserId)

  _validateUsersVetted: ->
    user = Users.findOne @userId
    forUser = Users.findOne @forUserId

    if (!user.isVetted()) or (!forUser.isVetted())
      error = new Meteor.Error(500, "Please ensure that both #{@userId} and #{@forUserId} are both vetted first.")
      logger.error(error)
      throw error

  makeChoice: (choice) ->
    @choice = choice # Needed because collection update does not update self

    if @active? && @active
      @_validateUsersVetted()
      Candidates.update @_id,
        $set:
          choice: choice
    else
      console.log "cannot make choices for candidates that are not active"

    if @matchesWithInverse()
      return @forUser().connectWithUserAndSendMessage @user(), choice

  findInverse: ->
    Candidates.findOne { forUserId: @userId, userId: @forUserId }

  createInverse: ->
    if @forUserId == Meteor.settings.CRAB_USER_ID || @userId == Meteor.settings.CRAB_USER_ID
      error = new Meteor.Error(501, 'Exception: Attempting to create crab as candidate')
      logger.error(error)
      throw error
    @_validateUsersVetted()
    Candidates.insert
      forUserId: @userId
      userId: @forUserId
      vetted: false
      active: false

  matchesWithInverse: ->
    if @choice != 'yes'
      return false
    inverse = @findInverse()
    return if inverse then inverse.choice == @choice else false

  makeChoiceForInverse: (choice) ->
    inverse = @findInverse()
    unless inverse?
      inverse = Candidates.findOne @createInverse()
    inverse.activate()
    inverse.makeChoice choice

  vet: ->
    @_validateUsersVetted()
    Candidates.update @_id,
      $set:
        vetted: true

  unvet: ->
    @_validateUsersVetted()
    Candidates.update @_id,
      $set:
        vetted: false
        active: false
        choice: null

  activate: ->
    @_validateUsersVetted()
    Candidates.update @_id,
      $set:
        vetted: true
        active: true

  deactivate: ->
    @_validateUsersVetted()
    Candidates.update @_id,
      $set:
        active: false
        choice: null

  remove: ->
    Candidates.remove @_id

  clientView: ->
    view = _.clone this
    delete view.forUserId
    return view
