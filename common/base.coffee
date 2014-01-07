Crawler     = require("crawler").Crawler
Hope        = require("hope")
require("colors")


Logger =

  ok: (type, msg, add_rainbow=false) ->
    if add_rainbow
      console.log "\n====================================================".rainbow
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
      Logger.ok("start", @name, true)
      do @_initialize
      @crawler = new Crawler
        maxConnections  : 10
        skipDuplicates  : true
        forceUTF8       : true
        callback        : @_parse
        onDrain         : @_onFinish

      if @authorization then @_authorization().then(@_crawl)
      else do @_crawl

    else Logger.error "Crawler is allready running"

  # Pushes a result object to @results
  addResult: (result) ->
    @results.push result

  queue: (data, callback=null) ->
    if typeof data is "string"
      data = uri: data, jQuery: true, callback: callback
    data.callback = data.callback or @_parse
    @_queuedUrls = @_queuedUrls or []
    if @_queuedUrls.indexOf(data.uri) is -1
      Logger.log "URL to scrap :: ", data.uri
      @_queuedUrls.push data.uri
      if @headers then data.headers = @headers
      @crawler.queue data

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
  _parse: (error, request, $) =>
    Logger.log "Parse URL " + request.uri + $("head title").text()
    if @parse then @parse.call @, error, request, $

  # Queues start urls to crawler
  _crawl: ->
    Logger.log "Start URLS " + @startUrls.join("; ")
    @crawler.queue @startUrls

  # Makes an authorization request to get the headers or set them by a custom callback
  _authorization: =>
    promise = new Hope.Promise()
    crawler_data =
      maxConnections  : 1
      onDrain         : ->
        Logger.ok "auth", "Authorization finished"
        do promise.done

    queue_data =
      uri       : @authorization.url
      method    : @authorization.method
      form      : @authorization.form
      jQuery    : false

    queue_data.callback = @authorization.callback or (request, response, $) =>
      @headers = response.headers

    authorization = new Crawler(crawler_data)
    authorization.queue(queue_data)
    return promise


module.exports = BaseCrawler
