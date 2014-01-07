mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.fuel
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  key           : type: String
  postal_code   : type: Number
  province      : type: String
  location      : type: String
  address       : type: String
  region        : type: String
  schedule      : type: String
  margin        : type: String
  gas_station   : type: String
  geoposition   : type: [Number], index: '2d'
  created_at    : type: Date, default: Date.now


SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  parameters.geoposition = parameters.geoposition or []
  parameters.key = parameters.geoposition.join("-") + "-" + parameters.address
  filter = key: parameters.key
  @findOneAndUpdate filter, parameters, {upsert: true}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    promise.done error, result
  promise


module.exports = db.model "Station", SchemaDef