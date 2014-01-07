Crawler     = require("crawler").Crawler
Hope        = require("hope")
require("colors")


Logger =

  rainbow: -> console.log "\n====================================================".rainbow

  ok: (type, msg) ->
    console.log ("[#{type.toUpperCase()}]".green + " :: " + msg).bold

  log: (msg) ->
    console.log "[ LOG ]".bold + " :: " + msg

  error: (msg) ->
    console.log ("[ERROR]".red + " :: " + msg).bold



class BaseCrawler

  debug: false

  constructor: ->
    @is_working = false

  # Starts crawling
  start: ->
    unless @is_working
      Logger.rainbow()
      Logger.ok "start", @name
      do @_initialize
      if @authorization
        @_authorization().then (error, result) => do @_crawl
      else do @_crawl
    else Logger.error "Crawler is allready running"

  # Pushes a result object to @results
  addResult: (result) ->
    @results.push result

  # Adds an url to crawl only if it hasn't been parsed (or adds queue object)
  queue: (data, callback=null) ->
    try
      if typeof data is "string"
        data = uri: data, jQuery: true, callback: callback
      data.callback = data.callback or @_parse
      data.headers = {}
      @_queuedUrls = @_queuedUrls or []
      if @_queuedUrls.indexOf(data.uri) is -1
        Logger.log "URL to scrap :: " + data.uri
        @_queuedUrls.push data.uri
        if @headers then data.headers = @headers
        @crawler.queue data
    catch e
      Logger.error e.toString()

  # Initializes all related vars
  _initialize: ->
    @_queuedUrls  = []
    @is_working   = true
    @results      = []
    @headers      = {}
    @crawler      = null

  # Triggered when not more urls to fetch
  _onFinish: () =>
    Logger.ok "finish", "No more URLs to fetch"
    @is_working = false
    if @onFinish then @onFinish.call @, @results
    else "onFinish function must be created to get results..."

  # Default parse method for startUrls
  _parse: (error, response, $) =>
    Logger.log "Parsing [" + response.uri + "]"
    if @parse then @parse.call @, error, response, $

  # Creates the crawler and queues to it start urls
  _crawl: ->
    @crawler = new Crawler
      maxConnections  : 10
      skipDuplicates  : true
      forceUTF8       : true
      callback        : @_parse
      onDrain         : @_onFinish

    Logger.log "Start URLS " + @startUrls.join("; ")
    @crawler.queue @startUrls

  # Makes an authorization request to get the headers or set them by a custom callback
  _authorization: ->
    promise = new Hope.Promise()
    auth = new Crawler {maxConnections: 1}
    auth.queue
      uri       : @authorization.uri
      method    : @authorization.method
      form      : @authorization.form
      jQuery    : false
      callback  : @authorization.callback or (error, response) =>
        @headers.cookie = response.headers['set-cookie'] or response.headers['Set-Cookie']
        promise.done error, response
    return promise


module.exports = BaseCrawler
