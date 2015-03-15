logger = Meteor.npmRequire('bunyan').createLogger(name: 'photos')
Future = Npm.require('fibers/future')
gm = Meteor.npmRequire('gm').subClass(imageMagick: true)
request = Meteor.npmRequire('request')
util = Npm.require('util')
IMAGE_SIZE = Meteor.settings.DEFAULT_IMAGE_SIZE or 640
graph = Meteor.npmRequire('fbgraph')

class @Image
  constructor: (id, userId, width, height, source) ->
    @id = id
    @userId = userId
    @width = width
    @height = height
    @source = source

  remoteId: ->
    util.format('%s/%s.jpg', @userId, @id)


class @FacebookPhotoService

  constructor: (containerUrl) ->
    @containerUrl = containerUrl
    @client = Meteor.npmRequire('pkgcloud').storage.createClient
      provider: 'azure'
      storageAccount: Meteor.settings.AZURE_ACCOUNTID or ''
      storageAccessKey: Meteor.settings.AZURE_ACCESSKEY or ''

  getFileURL: (file) ->
    util.format('%s%s.%s/%s/%s', @client.protocol, @client.config.storageAccount,
      @client.serversUrl, file.container, file.name)

  # @return a list of azure photo URLs
  copyPhotosToAzure: (imagesToDownload) ->
    # needed otherwise scoping doesn't work well
    self = this
    client = @client

    futures = _.map imagesToDownload, (image) ->
      future = new Future
      onComplete = future.resolver()

      client.getFile self.containerUrl or 'ketch-dev',
        image.remoteId(), (err, file) ->
          if file?
            console.log "image " + image.remoteId() + " exists. Not importing"
            onComplete err, self.getFileURL file
          else
            writeStream = client.upload
              container: self.containerUrl or 'ketch-dev'
              remote: image.remoteId()
              contentType: 'image/jpeg'

            writeStream.on 'success', (file) ->
              onComplete null, self.getFileURL file

            writeStream.on 'error', (err) ->
              logger.error err
              onComplete err

            startX = (image.width - IMAGE_SIZE) / 2
            startY = (image.height - IMAGE_SIZE) / 2
            console.log "Will import photo #{image.source}"
            # get the facebook photo and then crop it.
            gm(request.get(image.source)).crop(IMAGE_SIZE, IMAGE_SIZE, startX, startY).stream().pipe writeStream

      return future

    Future.wait futures
    azureUrls = []
    futures.forEach (future) ->
      result = future.get()
      # in the case that facebook did not have a large enough image,
      # result will be null
      if result != null
        azureUrls.push result
      return

    return azureUrls

  importPhotosForUser: (user) ->
    # TODO: graph should be instance variable, as should user (part of constructor)
    graph.setAccessToken user.services.facebook.accessToken
    graphGet = Meteor.wrapAsync(graph.get)

    # TODO: Use profile photos, not just photos of me
    profilePicturesAlbum = graphGet('/me/albums').data

    profilePicAlbumId = null
    profilePicturesAlbum.forEach (album) ->
      if album.name == "Profile Pictures"
        profilePicAlbumId = album.id

    # if the user does not have a profile picture album, default to photos of them.
    if profilePicAlbumId == null
      res = graphGet('/me/photos').data
    else
      res = graphGet(util.format('%s/photos', profilePicAlbumId)).data

    console.log "Will import facebook photos for #{user._id} : #{user.firstName}"
    imagesToDownload = []
    i = 0

    while i < res.length
      photo = res[i]
      # out of all images bigger than IMAGE_SIZE x IMAGE_SIZE, pick the
      # one that has the least number of pixels (to improve download).
      imageToCrop = null
      _totalPixels = 0
      photo.images.forEach (image) ->
        if image.height >= IMAGE_SIZE and image.width >= IMAGE_SIZE and image.height * image.width > _totalPixels
          imageToCrop = image
          _totalPixels = image.height * image.width

      if imageToCrop != null
        imageToCrop.id = photo.id
        imagesToDownload.push new Image photo.id, user._id,
          photo.width, photo.height, photo.source
      else
        console.log "Skipping photo", photo.id
      i++

    azureUrls = @copyPhotosToAzure imagesToDownload

    i = 0;
    userPhotos = []
    while i < azureUrls.length
      userPhoto = {}
      userPhoto.url = azureUrls[i]

      if i < Meteor.settings.PHOTO_COUNT_TO_DISPLAY
        userPhoto.active = true
      else
        userPhoto.active = false

      userPhoto.order = i
      userPhotos.push(userPhoto)
      i++

    Users.update user._id, $set: photos: userPhotos
    console.log "done uploading for #{user._id}"