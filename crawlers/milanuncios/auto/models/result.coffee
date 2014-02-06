mongoose    = require "mongoose"
Hope        = require "hope"
db          = require("../../../../crawler").Mongo.milanuncios
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema

  provider    : type: Number
  url         : type: String
  reference   : type: String, unique: true
  make        : type: String
  model       : type: String
  description : type: String
  fuel_type   : type: Number
  year        : type: Number
  kms         : type: Number
  price       : type: Number
  images      : [type: String]
  contact     : type: Object
  created_at  : type: Date, default: Date.now


SchemaDef.statics.saveAll = (results) ->
  promise = new Hope.Promise()
  @create results, (error, result) -> promise.done(error, result)
  promise

SchemaDef.statics.searchLastReferences = ->
  promise = new Hope.Promise()
  @find().sort(created_at: -1).limit(10).exec (error, results) ->
    promise.done error, (result.reference.toString() for result in results)
  promise


module.exports = db.model "Car", SchemaDef
