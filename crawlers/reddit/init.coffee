BaseCrawler   = require "../../common/base"
Hope          = require "hope"
ResultModel   = require "./models/result"

SEARCH_KEYWORDS = ["tapquo"]


class Reddit extends BaseCrawler
  name      : "Reddit tapquo"
  startUrls : do ->
    urls = ("http://es.reddit.com/search?q=#{kw}" for kw in SEARCH_KEYWORDS)
    urls

  parse: (response, request, $) =>
    $("#siteTable a.title").each (i, element) =>
      @queue element.href, @parseContent

  parseContent: (response, request, $) =>
    @addResult
      title       : $("#siteTable a.title").text()
      description : $("#siteTable div.md").text()
      url         : request.uri

  onFinish: (results) ->
    saveTasks = (_prepareSave(result) for result in results)
    Hope.join(saveTasks).then (error, result) ->
      console.log "Results saved!", error, result

_prepareSave = (result) -> ->
  ResultModel.register(result)


crawler = new Reddit()
crawler.start()
module.exports = -> @