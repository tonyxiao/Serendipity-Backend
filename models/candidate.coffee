
@Candidates = new Mongo.Collection 'candidates'
Candidates.timestampable()

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

  makeChoice: (choice) ->
    @choice = choice # Needed because collection update does not update self

    candidate = Candidates.findOne @_id
    if candidate.active? && candidate.active
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
      throw new Meteor.Error(501, "Attempting to create crab as candidate.")

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
    Candidates.update @_id,
      $set:
        vetted: true

  unvet: ->
    Candidates.update @_id,
      $set:
        vetted: false
        active: false
        choice: null

  activate: ->
    Candidates.update @_id,
      $set:
        vetted: true
        active: true

  deactivate: ->
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
