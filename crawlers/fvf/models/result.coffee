mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.fvf
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  competition     : type: ObjectId, ref: "Competition"
  journey         : type: Number
  group           : type: Number
  local_team      : type: ObjectId, ref: "Team"
  local_result    : type: Number
  visitant_team   : type: ObjectId, ref: "Team"
  visitant_result : type: Number
  created_at      : type: Date, default: Date.now

SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  @create parameters, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise


module.exports = db.model "Result", SchemaDef
