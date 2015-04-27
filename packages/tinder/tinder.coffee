
@fixtureNames = [
  "girls_1", "girls_2", "girls_3", "girls_4", "girls_5", "girls_6",
  "guys_1", "guys_2", "guys_3", "guys_4", "guys_5", "guys_6", "guys_7"
]

@getFixture = (name) ->
  JSON.parse Assets.getText "fixtures/#{name}.json"

@parseUserList = (data) ->
  (parseSingleUser(r) for r in data.results)

@parseSingleUser = (result) ->
  # TODO: Consider making fixture data deterministic rather than random
  firstName: result.name
  lastName: RandomData.lastName()
  about: result.bio
  photos: parsePhotos(result.photos)
  education: RandomData.school()
  age: RandomData.age() # XXX: Birthday is totally incorrect
  height: RandomData.height()
  location: RandomData.location()
  timezone: 'America/Los_Angeles'
  work: RandomData.job()
  gender: result.gender == 0 ? 'male' : 'female'
  createdAt: new Date
  updatedAt: new Date
  services:
    tinder:
      _id: result._id

@parsePhotos = (photos) ->
  # TODO: Consider copying photos to azure so we don't run into Tinder ip blocking us again
  # azureUrls = fbPhotoService.copyPhotosToAzure(images)
  (parseSinglePhoto(p) for p in photos)

@parseSinglePhoto = (photo) ->
  for file in photo.processedFiles
    if file.height == 640 and file.width == 640
      return file.url

Tinder =
  importFakeUsers: ->
    _(fixtureNames).each (fixture) ->
      data = getFixture fixture
      users = parseUserList data
      console.log "Will import #{users.length} users"

  clearFakeUsers: ->
    console.log "Noop, not implemented yet"
