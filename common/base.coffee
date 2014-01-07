Crawler     = require("crawler").Crawler
Hope        = require("hope")


class BaseCrawler

  debug: false

  constructor: ->
    @is_working = false

  start: ->
    unless @is_working
      console.log "\n\n----------------------------------------"
      console.log "Crawler \"#{@name}\" started !!"
      do @_initialize
      @crawler = new Crawler
        maxConnections  : 10
        skipDuplicates  : true
        forceUTF8       : true
        callback        : @_parse
        onDrain         : @_onFinish

      if @authorization then @_authorization().then(@_crawl)
      else do @_crawl

    else console.log "[ERROR] Crawler is allready running"

  addResult: (result) ->
    @results.push result

  queue: (data, callback=null) ->
    if typeof data is "string"
      data = uri: data, jQuery: true, callback: callback

    @_queuedUrls = @_queuedUrls or []
    if @_queuedUrls.indexOf(data.uri) is -1
      console.log "URL to scrap :: ", data.uri
      @_queuedUrls.push data.uri
      @crawler.queue data

  _initialize: ->
    @_queuedUrls  = []
    @is_working   = true
    @results      = []
    @headers      = {}
    @crawler      = null

  # Triggered when not more urls to fetch
  _onFinish: () =>
    console.log "This is the end..."
    @is_working = false
    if @onFinish then @onFinish.call @, @results
    else "onFinish function must be created to get results..."

  # Default parse method for startUrls
  _parse: (error, request, $) =>
    console.log "Parse URL -> ", request.uri, $("head title").text()
    if @parse then @parse.call @, error, request, $

  # Queues start urls to crawler
  _crawl: ->
    console.log "Start URLS :: ", @startUrls
    @crawler.queue @startUrls

  _authorization: =>
    promise = new Hope.Promise()
    crawler_data =
      maxConnections  : 1
      onDrain         : ->
        console.log "on authorization drain..."
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
