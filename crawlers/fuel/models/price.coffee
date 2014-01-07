mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.fuel
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  station       : type: ObjectId, ref: "Station"
  date          : type: Date
  fuel_type     : type: Number
  fuel_name     : type: String
  active        : type: Boolean, default: true
  price         : type: Number
  created_at    : type: Date, default: Date.now


SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  filter =
    station   : parameters.station
    fuel_type : parameters.fuel_type
    date      : parameters.date

  @findOneAndUpdate filter, parameters, {upsert: true}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise


module.exports = db.model "Price", SchemaDef