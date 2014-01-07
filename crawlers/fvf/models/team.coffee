mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.fvf
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId


SchemaDef = new Schema
  competition     : type: ObjectId, ref: "Competition"
  group           : type: Number
  team_id         : type: Number
  name            : type: String
  created_at      : type: Date, default: Date.now

SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  filter = team_id: parameters.team_id
  @findOneAndUpdate filter, parameters, {upsert: true}, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise


module.exports = db.model "Team", SchemaDef
