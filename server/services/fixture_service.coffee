
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

  # See sample_tinder_recs.json
  @importFromTinder: (data) ->
    for result in data.results
      console.log 'Will add user with name ' + result.name
      photosUrls = []
      result.photos.forEach (photo) ->
        photo.processedFiles.forEach (processedPhoto) ->
          if processedPhoto.height == 640 and processedPhoto.width == 640
            photosUrls.push processedPhoto.url

      Users.upsert 'services.tinder._id': result._id,
        $set:
          firstName: result.name
          about: result.bio
          birthday: result.birthday
          photoUrls: photosUrls
          education: @randomSchool()
          age: @randomAge()
          location: @randomLocation()
          work: @randomJob()
          services:
            tinder:
              _id: result._id
        $setOnInsert:
          createdAt: new Date
