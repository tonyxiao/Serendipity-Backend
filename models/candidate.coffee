
@Candidates = new Mongo.Collection 'candidates'
Candidates.timestampable()


# MARK: - Instance Methods
Candidates.helpers
  user: ->
    Users.findOne(@matchedUserId)

  forUser: ->
    Users.findOne(@matcherId)

  makeChoice: (choice) ->
    Candidates.update @_id,
      $set:
        choice: choice

  findInverse: ->
    Candidates.findOne { forUserId: @userId, userId: @forUserId }

  matchesWithInverse: ->
    inverse = @findInverse()
    return if inverse then inverse.choice == @choice else false

  forceChoiceForInverse: (choice) ->
    Candidates.update {
      forUserId: @userId,
      userId: @forUserId
    }, {
      $set:
        choice: choice,
    }, {
      upsert: true
    }


# TODO: Remove once outdated references are refactored
@candidates = Candidates
