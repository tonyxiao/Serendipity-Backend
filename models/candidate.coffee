
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


# MARK: - Instance Methods
Candidates.helpers
  user: ->
    Users.findOne(@userId)

  forUser: ->
    Users.findOne(@forUserId)

  makeChoice: (choice) ->
    @choice = choice # Needed because collection update does not update self
    Candidates.update @_id,
      $set:
        choice: choice
    if @matchesWithInverse()
      return @forUser().connectWithUser @user(), choice

  findInverse: ->
    Candidates.findOne { forUserId: @userId, userId: @forUserId }

  createInverse: ->
    Candidates.insert
      forUserId: @userId
      userId: @forUserId

  matchesWithInverse: ->
    inverse = @findInverse()
    return if inverse then inverse.choice == @choice else false

  makeChoiceForInverse: (choice) ->
    Candidates.upsert {
      forUserId: @userId
      userId: @forUserId
    }, {
      $set:
        choice: choice
        # Collection-behavior doesn't seem to work here, need to explicitly set timestamp
        createdAt: new Date()
        updatedAt: new Date()
    }

  remove: ->
    Candidates.remove @_id

  clientView: ->
    view = _.clone this
    delete view.forUserId
    return view
