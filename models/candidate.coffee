
@candidates = new Mongo.Collection 'candidates'
candidates.timestampable()

candidates.helpers
  test: ->
    return "test name"