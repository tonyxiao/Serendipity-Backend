logger = new KetchLogger 'fixture'

class @FixtureService

  # @param schools an array of {@code education} objects from '/me' graph api response
  @mostRecentSchool: (schools = []) ->
    mostRecent = undefined
    schools.forEach (school) ->
      if school? && school.year? && school.year.name? && school.school.name?
        if mostRecent == undefined || school.year.name > mostRecent.year.name
          mostRecent = school
    return mostRecent

  # @param schools an array of {@code work} objects from '/me' graph api response
  @mostRecentJob: (jobs = []) ->
    mostRecent = undefined
    jobs.forEach (job) ->
      if job.start_date? && job.employer.name?
        if mostRecent == undefined || job.start_date > mostRecent.start_date
          mostRecent = job
    return mostRecent

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
