BaseCrawler   = require "../../common/basev2"
Hope          = require "hope"
$             = require "cheerio"
ResultModel   = require "./models/result"


segundaMano = new BaseCrawler()

segundaMano.on "finish", ->
  console.log(results);
  console.error("Num results :: ", results.length)


results = []

trim = (str) -> str.trim().replace(/\n|\t/g, "")


parseResult = (w) ->
  title:    trim(w.find("h1.productTitle").text())
  date:     trim(w.find("li.ad_actualPrice").text())
  price:    trim(w.find("li.adInfo_preu").text())
  contact:  trim(w.find("li.adview_c_name > b").text() + " " + w.find("li.adInfo_tel a").text())



offer = (error, response, window) ->
  results.push(parseResult(window))
  # results.push window.find("title").text()

offers = (error, response, window) ->
  window.find("a.subjectTitle").each (i, a) ->
    segundaMano.queue $(a).attr("href"), offer


segundaMano.queue("http://www.segundamano.es/coches-de-segunda-mano/?sort_by=1&od=1&o=1", offers)
segundaMano.start()

module.exports = ->
  results = []
