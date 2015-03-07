path = Npm.require('path')
sleep = Meteor.npmRequire('sleep')

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

  # @param schools an array of {@code education} objects from '/me' graph api response
  @mostRecentSchool: (schools = []) ->
    mostRecent = undefined
    schools.forEach (school) ->
      if school? && school.year? && school.year.name? && school.school.name?
        if mostRecent == undefined || school.year.name > mostRecent.year.name
          mostRecent = school
    return mostRecent

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

  # @param schools an array of {@code work} objects from '/me' graph api response
  @mostRecentJob: (jobs = []) ->
    mostRecent = undefined
    jobs.forEach (job) ->
      if job.start_date? && job.employer.name?
        if mostRecent == undefined || job.start_date > mostRecent.start_date
          mostRecent = job
    return mostRecent

  @randomAge: ->
    _.sample [19..35]

  # @param birthday a string representing the {@code birthday} object
  # from '/me' graph api response
  # @return an integer age for the user
  @age: (birthday) ->
    if birthday?
      birth = new Date birthday
      today = new Date

      age = today.getYear() - birth.getYear()
      if today.getMonth() < birth.getMonth()
        age--

      if birth.getMonth() == today.getMonth() && today.getDate() < birth.getDate()
        age--

      return age

  @randomHeight: ->
    _.sample [150...210] # in cm

  @randomGender: ->
    _.sample ['male', 'female']

  # See sample_tinder_recs.json
  @importFromTinder: (data) ->
    fbPhotoService = new FacebookPhotoService("tinder")

    for result in data.results
      console.log 'Will add user with name ' + result.name
      images = []
      result.photos.forEach (photo) ->
        photo.processedFiles.forEach (processedPhoto) ->
          if processedPhoto.height == 640 and processedPhoto.width == 640
            imageId = path.basename(processedPhoto.url, '.jpg')
            images.push new Image imageId, result._id, 640, 640, processedPhoto.url

      azureUrls = fbPhotoService.copyPhotosToAzure(images)

      # TODO: not sleeping sometimes results in the meteor server getting stuck. Since
      # this is only a tool for debugging, I added 200ms of sleep, which seems to fix the
      # problem. A separate task would be to figure out why this is the case.
      sleep.usleep(200 * 1000) # 200 ms

      # TODO: Why doesn't this work on heroku? Users.upsert 'services.tinder._id': result._id,
      # #  { [MongoError: The dotted field 'services.tinder._id' in 'services.tinder._id' is not valid for storage.] stack: [Getter] }
      Users.update 'services\uff0Etinder\uff0E_id': result._id,
        { $set:
          firstName: result.name
          about: result.bio
          photoUrls: azureUrls
          education: @randomSchool()
          age: @randomAge()
          height: @randomHeight()
          location: @randomLocation()
          timezone: 'America/Los_Angeles'
          work: @randomJob()
          gender: @randomGender()
          services:
            tinder:
              _id: result._id
              birthday: result.birthday
        $setOnInsert:
          createdAt: new Date }
        { upsert: true }

    return data.results.length
