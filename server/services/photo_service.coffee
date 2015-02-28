logger = Meteor.npmRequire('bunyan').createLogger(name: 'photos')
Future = Npm.require('fibers/future')
gm = Meteor.npmRequire('gm').subClass(imageMagick: true)
request = Meteor.npmRequire('request')
util = Npm.require('util')
PHOTO_COUNT = process.env.DEFAULT_PHOTO_COUNT or 4
IMAGE_SIZE = process.env.DEFAULT_IMAGE_SIZE or 640
graph = Meteor.npmRequire('fbgraph')

client = Meteor.npmRequire('pkgcloud').storage.createClient
  provider: 'azure'
  storageAccount: process.env.AZURE_ACCOUNTID or ''
  storageAccessKey: process.env.AZURE_ACCESSKEY or ''


class @FacebookPhotoService

  @importPhotosForUser: (user) ->
    # TODO: graph should be instance variable, as should user (part of constructor)
    graph.setAccessToken user.services.facebook.accessToken
    graphGet = Meteor.wrapAsync(graph.get)

    # TODO: Use profile photos, not just photos of me
    profilePicturesAlbum = graphGet('/me/albums').data

    profilePicAlbumId = null
    profilePicturesAlbum.forEach (album) ->
      if album.name == "Profile Pictures"
        console.log "profile pic album found"
        profilePicAlbumId = album.id

    # if the user does not have a profile picture album, default to photos of them.
    if profilePicAlbumId == null
      res = graphGet('/me/photos').data
    else
      res = graphGet(util.format('%s/photos', profilePicAlbumId)).data

    console.log "Will import facebook photos for #{user._id} : #{user.firstName}"
    imagesToDownload = []
    i = 0
    console.log "res length #{res.length} photocount #{PHOTO_COUNT}"
    while i < res.length and imagesToDownload.length < PHOTO_COUNT
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
        imagesToDownload.push imageToCrop

      else
        console.log "Skipping photo", photo
      i++


    futures = _.map imagesToDownload, (image) ->
      future = new Future
      onComplete = future.resolver()
      # TODO: Is it safe to assume jpg image?
      writeStream = client.upload
        container: process.env.AZURE_CONTAINER or 'ketch-dev'
        remote: util.format('%s/%s.jpg', user._id, image.id)
        contentType: 'image/jpeg'

      writeStream.on 'success', (file) ->
        url = util.format('%s%s.%s/%s/%s', client.protocol, client.config.storageAccount, client.serversUrl, file.container, file.name)
        onComplete null, url

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

    Users.update user._id, $set: photoUrls: azureUrls