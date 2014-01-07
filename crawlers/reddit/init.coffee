BaseCrawler   = require "../../common/base"
Hope          = require "hope"
ResultModel   = require "./models/result"

SEARCH_KEYWORDS = ["tapquo", "quojs", "monocle", "coffeescript", "ajax"]
SEARCH_KEYWORDS = ["tapquo"]


class Reddit extends BaseCrawler

  name      : "Reddit tapquo"

  authorization:
    uri         : "https://ssl.reddit.com/api/login/xxxxxxxxxxxx"
    method      : "POST"
    form        :
      op        : "login"
      user      : "xxxxxxxxxxxx"
      passwd    : "yyyyyyyyyyyyyy"
      api_type  : "json"

  startUrls : do ->
    ("http://es.reddit.com/search?q=#{keyword}" for keyword in SEARCH_KEYWORDS)

  parse: (error, response, $) =>
    $("#siteTable a.title").each (i, element) =>
      if _validLink element.href
        @queue element.href, @parseContent
      else
        @addResult
          title       : element.innerText
          description : ""
          url         : element.href

  parseContent: (error, response, $) =>
    if response
      @addResult
        url         : response.uri
        title       : $("#siteTable a.title").text()
        description : $("#siteTable div.md").text()

  onFinish: (results) ->
    saveTasks = (_prepareSave(result) for result in results)
    Hope.join(saveTasks).then (error, result) ->
      console.log "Results saved!", error, result

_validLink = (uri) ->
  uri.slice(-1) is "/" and uri.substring(0, 21) is "http://es.reddit.com/"


_prepareSave = (result) -> ->
  ResultModel.register(result)


crawler = new Reddit()
module.exports = -> crawler.start()