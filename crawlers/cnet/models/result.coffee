mongoose    = require("mongoose")
Hope        = require("hope")
db          = require("../../../crawler").Mongo.cnet
Schema      = mongoose.Schema
ObjectId    = Schema.ObjectId



SchemaDef = new Schema
  url         : type: String, unique: true
  title       : type: String
  summary     : type: String
  bodyHtml    : type: String
  bodyText    : type: String
  extra       : type: Object, default: {}
  created_at  : type: Date, default: Date.now


SchemaDef.statics.register = (parameters) ->
  promise = new Hope.Promise()
  @create parameters, (error, result) ->
    if error then console.error "[#{error.name}] :: #{error.message}"
    else promise.done error, result
  promise


module.exports = db.model "News", SchemaDef