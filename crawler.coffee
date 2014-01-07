require "js-yaml"
require "time"

config      = require("./crawler.yml")
env         = require("./environment/#{config.environment}.yml")
Cron        = require("cron").CronJob
Mongoose    = require("mongoose")
Hope        = require("hope")


class Crawler

  constructor: -> @

  connectMongo: =>
    console.log "================================================"
    console.log "Mongo connections"
    console.log "================================================"
    promise = new Hope.Promise()
    tasks = []
    @Mongo = {}
    tasks.push @_mongoConnection(mongoData) for mongoData in env.mongo
    Hope.join(tasks).then (error, result) =>
      promise.done error, result
    promise

  _mongoConnection: (mongoData) => =>
    promise = new Hope.Promise()
    connectionUrl = "mongodb://"
    if mongoData.user and mongoData.password
      connectionUrl += "#{mongoData.user}:#{mongoData.password}@"
    connectionUrl += mongoData.host
    connectionUrl += ":#{mongoData.port}" if mongoData.port
    connectionUrl += "/#{mongoData.db}"
    console.log connectionUrl
    @Mongo[mongoData.name] = Mongoose.createConnection connectionUrl, (error, result) ->
      if not error then console.log "- Connected to #{mongoData.name}"
      promise.done error, result
    promise

  initCronjobs = ->
    console.log "================================================"
    console.log "Init cronjobs"
    console.log "================================================"
    for task in config.tasks
      console.log "- Cron registered: #{task.name}"
      new Cron
        cronTime  : task.schedule
        onTick    : require("./crawlers/#{task.file}")
        start     : true
        timeZone  : (task.timezone) or "Europe/Madrid"

  run: ->
    tasks = []
    tasks.push @connectMongo
    Hope.shield(tasks).then (error, result) =>
      error = error.filter (e) -> e != undefined
      if error.length then console.error "[ERROR] :: ", error
      else do initCronjobs


module.exports = new Crawler()
