mongoose    = require "mongoose"
Hope        = require "hope"
db          = require("../../../crawler").Mongo.quinielas
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  journey     : type: Number
  index       : type: Number
  team1       : type: String
  team2       : type: String
  result      : type: String
  created_at  : type: Date, default: Date.now


SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  query =
    journey : parameters.journey
    index   : parameters.index

  @findOneAndUpdate query, parameters, {upsert: true}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result

  promise


module.exports = db.model("Result", SchemaDef)
