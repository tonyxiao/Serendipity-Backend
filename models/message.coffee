
@messages = new Mongo.Collection 'messages'
messages.timestampable()