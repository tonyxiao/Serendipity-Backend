
class @FixtureService

  @randomSchool: ->
    _.sample [
      'Harvard'
      'Yale'
      'Princeton'
      'Columbia'
      'Cornell'
      'Dartmouth'
      'Penn'
    ]

  @randomLocation: ->
    _.sample [
      'San Francisco, CA'
      'Mountain View, CA'
      'Palo Alto, CA'
      'Menlo Park, CA'
      'Sausalito, CA'
      'San Mateo, CA'
      'Cupertino, CA'
      'Sunnyvale, CA'
      'Berkeley, CA'
    ]

  @randomJob: ->
    _.sample [
      'Google'
      'Goldman Sachs'
      'Shell'
      'Boston Consulting Group'
      'Ben & Jerrys'
      'In N Out'
      'Facebook'
    ]

  @randomAge: ->
    _.sample [19..35]

  @randomHeight: ->
    _.sample [150...210] # in cm

  @randomGender: ->
    _.sample ['male', 'female']

  # See sample_tinder_recs.json
  @importFromTinder: (data) ->
    for result in data.results
      console.log 'Will add user with name ' + result.name
      photosUrls = []
      result.photos.forEach (photo) ->
        photo.processedFiles.forEach (processedPhoto) ->
          if processedPhoto.height == 640 and processedPhoto.width == 640
            photosUrls.push processedPhoto.url

      # TODO: Why doesn't this work on heroku? Users.upsert 'services.tinder._id': result._id,
      # #  { [MongoError: The dotted field 'services.tinder._id' in 'services.tinder._id' is not valid for storage.] stack: [Getter] }
      Users.upsert 'services.tinder._id': result._id,
        $set:
          firstName: result.name
          about: result.bio
          photoUrls: photosUrls
          education: @randomSchool()
          age: @randomAge()
          height: @randomHeight()
          location: @randomLocation()
          work: @randomJob()
          gender: @randomGender()
          services:
            tinder:
              _id: result._id
              birthday: result.birthday
        $setOnInsert:
          createdAt: new Date

    return data.results.length
