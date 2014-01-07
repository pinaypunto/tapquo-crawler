ResultModel = require "./models/result"
BaseCrawler = require "../../common/base"


class CNET extends BaseCrawler

  name        : "CNet"
  startUrls   : ["http://news.cnet.com/"]

  parse: (request, response, $) ->
    $("a[href]").each (index, link) =>
      href = $(link).attr("href").trim()
      newsRegexp = new RegExp("^/\\d{1,6}-\\d{1,6}_\\d{1,3}-\\d{1,10}-\\d{1,4}/.*/$", "")
      if href.match(newsRegexp)
        @queue "http://news.cnet.com#{href}", @parseArticle

  parseArticle: (request, response, $) =>
    body = $("div.post > div.postBody")
    @addResult
      url       : response.request.href
      title     : $("div.post > header[section=title] > h1").text()
      summary   : $("div.post > header[section=title] > p#introP").text()
      bodyHtml  : body.html()
      bodyText  : body.text()

  onFinish: (results) ->
    console.log "Finished with #{results.length} results"
    ResultModel.register results


crawler = new CNET()
console.log crawler.is_working
module.exports = -> crawler.start()
