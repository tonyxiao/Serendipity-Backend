jsonfile = Meteor.npmRequire 'jsonfile'
path = Npm.require 'path'

fixtureNames = [
  "girls_1", "girls_2", "girls_3", "girls_4", "girls_5", "girls_6",
  "guys_1", "guys_2", "guys_3", "guys_4", "guys_5", "guys_6", "guys_7"
]

getFixture = (name) ->
  filepath = path.join process.env.PWD, "server/fixtures/private/#{name}.json"
  jsonfile.readFileSync filepath

parseUserList = (data) ->
  (parseSingleUser(r) for r in data.results)

parseSingleUser = (result) ->
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
  gender: if result.gender == 0 then 'male' else 'female'
  vetted: 'yes'
  status: 'active'
  _id: result._id
  services:
    tinder:
      _id: result._id

parsePhotos = (photos) ->
  # TODO: Consider copying photos to azure so we don't run into Tinder ip blocking us again
  # Especially for admin website we also need https urls for photos
  # azureUrls = fbPhotoService.copyPhotosToAzure(images)
  (parseSinglePhoto(p) for p in photos)

parseSinglePhoto = (photo) ->
  for file in photo.processedFiles
    if file.height == 640 and file.width == 640
      return url: file.url, active: true

@Tinder =

  importFakeUsers: (maxCount) ->
    count = 0
    for fixtureName in _.shuffle(fixtureNames)
      users = parseUserList getFixture fixtureName
      for user in users
        Users.upsert user._id, $set: user
        count += 1
        if maxCount? and count == maxCount
          return count
    return count

  clearFakeUsers: ->
    Users.remove 'services.tinder': $ne: null
