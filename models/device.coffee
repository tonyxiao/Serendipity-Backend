logger = new KetchLogger 'devices'

@Devices = new Mongo.Collection 'devices'
Devices.attachBehaviour('timestampable')

@DeviceSchema = new SimpleSchema
  _id:
    type: String
    min: 1 # not empty
  appId:
    type: String
    min: 1 # not empty
    optional: true
  apsEnv:
    type: String
    min: 1 # not empty
    optional: true
  build:
    type: String
    min: 1 # not empty
    optional: true
  lat:
    type: Number
    optional: true
    decimal: true
  long:
    type: Number
    optional: true
    decimal: true
  timestamp:
    type: Date
    optional: true
  pushToken:
    type: String
    min: 1 # not empty
    optional: true
  settings:
    type: Object
    blackbox: true
    optional: true
  updatedAt:
    type: Date
  version:
    type: String
    min: 1
    optional: true

Devices.attachSchema @DeviceSchema