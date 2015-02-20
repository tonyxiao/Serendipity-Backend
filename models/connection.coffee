
@connections = new Mongo.Collection 'connections'
connections.timestampable()