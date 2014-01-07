mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.fvf
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  id_category     : type: Number
  category_name   : type: String
  id_competition  : type: Number, unique: true
  name            : type: String
  created_at      : type: Date, default: Date.now

SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  filter = id_competition: parameters.id_competition
  @findOneAndUpdate filter, parameters, {upsert: true}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise

SchemaDef.statics.get = (id) ->
  promise = new Hope.Promise()
  @findOne {id_competition: id}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise

module.exports = db.model "Competition", SchemaDef
