
class @FixtureService

  # See sample_tinder_recs.json
  @importFromTinder: (data) ->
    schools = [
      'Harvard'
      'Yale'
      'Princeton'
      'Columbia'
      'Cornell'
      'Dartmouth'
      'Penn'
    ]
    locations = [
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
    jobs = [
      'Google'
      'Goldman Sachs'
      'Shell'
      'Boston Consulting Group'
      'Ben & Jerrys'
      'In N Out'
      'Facebook'
    ]

    for result in data.results
      console.log 'Will add user with name ' + result.name
      photosUrls = []
      result.photos.forEach (photo) ->
        photo.processedFiles.forEach (processedPhoto) ->
          if processedPhoto.height == 640 and processedPhoto.width == 640
            photosUrls.push processedPhoto.url

      Users.upsert 'services.tinder._id': result._id,
        firstName: result.name
        about: result.bio
        birthday: result.birthday
        createdAt: new Date
        photoUrls: photosUrls
        education: _.sample schools
        age: _.sample [19..35]
        location: _.sample locations
        work: _.sample jobs
        services:
          tinder:
            _id: result._id
