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
    res = graphGet('/me/photos').data
    imagesToDownload = []
    i = 0
    while i < res.length and i < PHOTO_COUNT
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
      i++

    futures = _.map imagesToDownload, (image) ->
      future = new Future
      onComplete = future.resolver()
      writeStream = client.upload(
        container: process.env.AZURE_CONTAINER or 's10-dev'
        remote: util.format('%s/%s', currentUser._id, image.id))
      writeStream.on 'success', (file) ->
        url = util.format('%s%s.%s/%s/%s', client.protocol, client.config.storageAccount, client.serversUrl, file.container, file.name)
        onComplete null, url
        return
      writeStream.on 'error', (err) ->
        logger.error err
        onComplete err
        return
      startX = (image.width - IMAGE_SIZE) / 2
      startY = (image.height - IMAGE_SIZE) / 2
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