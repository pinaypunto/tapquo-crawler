mongoose    = require "mongoose"
Hope        = require "hope"
db          = require("../../../crawler").Mongo.segundamano
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  title       : type: String
  description : type: String
  url         : type: String, unique: true
  created_at  : type: Date, default: Date.now


SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  @create parameters, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise


module.exports = db.model "Result", SchemaDef
