
@Candidates = new Mongo.Collection 'candidates'
Candidates.timestampable()

Candidates.helpers
  user: ->
    Users.findOne(@matchedUserId)

  forUser: ->
    Users.findOne(@matcherId)


# TODO: Remove once outdated references are refactored
@candidates = Candidates
