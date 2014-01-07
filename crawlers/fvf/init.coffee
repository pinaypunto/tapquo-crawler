Hope        = require "hope"
Competition = require "./models/competition"
Team        = require "./models/team"
Result      = require "./models/result"
BaseCrawler = require "../../common/base"


class FVF extends BaseCrawler

  startUrls: [
    "http://www.fvf-bff.org/publico/resultados.asp?idioma=ca"
  ]

  # startUrl parse
  # sets copmetitions data and scrps all of them
  parse: (request, response, $) ->
    console.log "Parsing start url :: ", response.request.path
    boxes = $(".caja")
    categories = []
    competitions = []
    boxes.each (i, box) =>
      box = $(box)
      super_category = box.children("h4").text()
      box.find("div.acc-group").each (j, group) =>
        group = $(group)
        button = group.children("button.btn-link")
        category = super_category + " / " + button.text()
        group.find("a[href].competicion.span5").each (k, link) =>
          data = @_getCompetitionData $(link)
          data.category_name = category
          @competitions = @competitions or {}
          @competitions["comp-#{data.id_competition}"] = data
          competitionUrl = "http://www.fvf-bff.org/publico/resultadosJornada.asp?idioma=ca&idCategoria=#{data.id_category}&idCompeticion=#{data.id_competition}"
          @queue competitionUrl, @parseCompetition

  parseCompetition: (request, response, $) =>
    console.log "Parsing competition :: ", response.request.path
    competition = parseInt(_getUrlParameter(response.request.path, "idCompeticion"), 10)

    # get current page results
    $("div.caja").each (i, box) =>
      box = $(box)
      parts = box.children("h4").text().replace(/[^0-9|\-]+/g, '').split("-")
      group = parseInt(parts[0], 10)
      journey = parseInt(parts[1], 10)
      box.find("table.table.table-striped > tbody > tr").each (i, tr) =>
        localLink = $(tr).find("td.local > a")
        visitantLink = $(tr).find("td.visitante > a")
        resultTd = $(tr).find("td.resultado")
        if localLink.length and visitantLink.length and resultTd.length
          local_team = localLink.text().trim()
          local_id   = localLink.attr("href").replace(/[^0-9|\-]+/g, '')
          visitant_team = visitantLink.text().trim()
          visitant_id   = visitantLink.attr("href").replace(/[^0-9|\-]+/g, '')
          result = resultTd.text().split("-")
          if result.length is 2
            local_result = parseInt(result[0].replace(/\s/g, ""), 10)
            visitant_result = parseInt(result[1].replace(/\s/g, ""), 10)
            @addResult
              competition     : competition
              group           : group
              journey         : journey
              local_team      : local_team
              visitant_team   : visitant_team
              local_id        : parseInt(local_id, 10)
              visitant_id     : parseInt(visitant_id, 10)
              local_result    : if isNaN(local_result) then null else local_result
              visitant_result : if isNaN(visitant_result) then null else visitant_result

    # queue other dates of this competition
    # $("select[name=selFechaJornada] option:not([value=''])").each (i, option) =>
    #   option = $(option)
    #   path = response.request.path.replace(/&fecha=.+/g, "")
    #   @queue "http://www.fvf-bff.org#{path}&fecha=#{option.val()}", @parseCompetition


  _getCompetitionData: (link) ->
    name = link.text().replace(/\ +/g, " ")
    parts = link.attr("href").split("&")
    id_competition = null
    for part in parts
      param = part.split("=")
      if param[0] is "idCompeticion" then id_competition = parseInt(param[1], 10)
      if param[0] is "idCategoria" then id_category = parseInt(param[1], 10)

    id_competition  : id_competition
    id_category     : id_category
    name            : name

  onFinish: (results) =>
    console.log "Saving results..."
    tasks = (@_saveResult(result) for result in results)
    Hope.join(tasks).then (error, result) ->
      console.log "Saved #{results.length} results"


  _saveResult: (data) => =>
    promise = new Hope.Promise()
    competition = @competitions["comp-#{data.competition}"]
    Competition.register(competition).then (error, competition) ->
      tasks = []

      tasks.push -> Team.register
        competition: competition._id
        group: data.group
        team_id: data.local_id
        name: data.local_team

      tasks.push -> Team.register
        competition: competition._id
        group: data.group
        team_id: data.visitant_id
        name: data.visitant_team

      Hope.join(tasks).then (error, result) ->
        local    = result[0]
        visitant = result[1]
        result_data =
          competition     : competition._id
          group           : data.group
          journey         : data.journey
          local_team      : local
          visitant_team   : visitant
          local_result    : data.local_result
          visitant_result : data.visitant_result

        Result.register(result_data).then (error, result) ->
          promise.done error, result

    return promise


_getUrlParameter = (url, param) ->
  url_parts = url.split("&")
  for part in url_parts
    parts = part.split("=")
    if parts[0] is param then return parts[1]
  return ""


crawler = new FVF()
module.exports = -> crawler.start()



