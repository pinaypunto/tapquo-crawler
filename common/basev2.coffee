cheerio = require("cheerio")
request = require("request")


DEFAULT =
  headers       : "user-agent": "request"
  max_threads   : 40


class Crawler

  constructor: (options = {}) ->
    @events = {}
    @options = {}
    @options.headers = options.headers or DEFAULT.headers
    @options.max_threads = options.max_threads or DEFAULT.max_threads
    do @_initialize

  #============================================================
  # Instance public methods
  on: (event_name, callback) ->
    @events[event_name] = @events[event_name] or []
    @events[event_name].push(callback) if @events[event_name].indexOf(callback) is -1

  trigger: (event_name, args...) ->
    return false unless @events[event_name]
    callback.apply(@, args) for callback in @events[event_name]

  queue: (request_data, callback) ->
    request_data = (if typeof request_data is "string" then url: request_data else request_data)
    if @parsed_urls.indexOf(request_data.url) is -1 and @pending_urls.indexOf(request_data.url) is -1
      @queue_data[request_data.url] = {data: request_data, callback: callback}
      @pending_urls.push(request_data.url)

  start: ->
    return false if @started is true
    @started = true
    @_checkQueue()
    return

  #============================================================
  # Instance private methods
  _initialize: ->
    @started = false
    @current_threads = 0
    @parsed_urls = []
    @pending_urls = []
    @queue_data = {}

  _lazyRequestCallback: (url) ->
    (error, response, body) =>
      @_receiveResponse.call(@, error, response, cheerio(body), url)

  _checkQueue: ->
    url = @pending_urls.shift()
    while url
      @_makeRequest(@queue_data[url].data, @_lazyRequestCallback(url))
      @parsed_urls.push(url)
      @current_threads++
      if @current_threads >= @options.max_threads then break
      url = @pending_urls.shift()

    if @current_threads is 0
      @trigger("finish")
      do @_initialize

  _makeRequest: (data, callback) ->
    data.headers = data.headers or @options.headers
    data.encoding = "binary" or @options.encoding
    request data, callback
    return

  _receiveResponse: (error, response, body, url) ->
    @current_threads--
    @trigger "response", error, response, body, url
    if not error and response.statusCode is 200
      @queue_data[url].callback.call(this, error, response, body)
      @_checkQueue()
    return


module.exports = Crawler

