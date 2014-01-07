Hope        = require "hope"
ResultModel = require "./models/result"
BaseCrawler = require "../../common/base"


class ResultsQuinielas extends BaseCrawler

  name      : "Quinielas AS"
  startUrls : ["http://www.as.com/quiniela/"]

  parse: (request, response, $) ->
    journey = $("table.tab_quiniela > caption > strong").text().split(" ").slice(-1)
    $("table.tab_quiniela > tbody > tr").each (index, tr) =>
      @addResult
        journey : parseInt(journey, 10)
        index   : parseInt($(tr).find("td.pos").text(), 10)
        team1   : $(tr).find("td.equipo:nth(0)").text()
        team2   : $(tr).find("td.equipo:nth(1)").text()
        result  : $(tr).find("td.resultado > .marcado").text().toLowerCase()

  onFinish: (results) ->
    saveTasks = (_prepareSave(result) for result in results)
    Hope.join(saveTasks).then (error, result) ->
      console.log "Results saved!"
      console.log "- errors :: ", (error.filter (x) -> x != null).length
      console.log "- results :: ", result.length

_prepareSave = (result) -> ->
  ResultModel.register(result)


crawler = new ResultsQuinielas()
module.exports = -> crawler.start()