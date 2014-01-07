BaseCrawler   = require "../../common/base"
Hope          = require "hope"
Station       = require "./models/station"
Price         = require "./models/price"


PROVINCES = [
  "01","02","03","04","33","05","06","07","08","09","10","11","39","12","51",
  "13","14","15","16","17","18","19","20","21","22","23","24","25","27","28",
  "29","52","30","31","32","34","35","36","26","37","38","40","41","42","43",
  "44","45","46","47","48","49","50"
]

FUEL_TYPES = [
  {id: 1, name: "Gasolina 95 (G.Protección)"},
  {id: 3, name: "Gasolina 98"},
  {id: 4, name: "Gasóleo A habitual"},
  {id: 5, name: "Nuevo gasóleo A"},
  {id: 6, name: "Gasóleo B"},
  {id: 7, name: "Gasóleo C"},
  {id: 8, name: "Biodiésel"},
  {id: 15, name: "Gasolina 95"},
  {id: 16, name: "Bioetanol"},
  {id: 17, name: "Gases licuados del petróleo"},
  {id: 18, name: "Gas natural comprimido"}
]



BASE_URL  = "http://geoportalgasolineras.es/searchAddress.do?"
BASE_URL += "nomMunicipio="
BASE_URL += "&rotulo="
BASE_URL += "&tipoVenta=false"
BASE_URL += "&nombreVia="
BASE_URL += "&numVia="
BASE_URL += "&codPostal="
BASE_URL += "&economicas=true"
BASE_URL += "&tipoBusqueda=0"
BASE_URL += "&ordenacion=P"


class Fuel extends BaseCrawler

  name      : "Fuel crawler"
  startUrls : do ->
    urls = []
    for fuel in FUEL_TYPES
      for prov in PROVINCES
        urls.push("#{BASE_URL}&nomProvincia=#{prov}&tipoCarburante=#{fuel.id}&posicion=0")
    urls

  _getText: (el) -> el.text().trim().replace("/\ */g", " ")

  _getUrlParam: (url, param) ->
    parts = url.split("?")[1].split("&")
    for part in parts
      keyVal = part.split("=")
      if keyVal[0] is param then return keyVal[1]
    return ""

  parse: (request, response, $) =>

    # get results from this page
    id_province = parseInt(@_getUrlParam(response.request.path, "nomProvincia"), 10)
    fuel_type = parseInt(@_getUrlParam(response.request.path, "tipoCarburante"), 10)
    currentPos = parseInt(@_getUrlParam(response.request.path, "posicion"), 10)

    console.log "Parsing -> Prov:#{id_province}, Fuel:#{fuel_type}, Pos:#{currentPos}"

    $("table.tabladatos > tbody > tr").each (i, tr) =>
      tr = $(tr)
      position = null
      if tr.find("td:eq(10) > img").length
        position = tr.find("td:eq(10) > img").attr("onclick").replace(/[^0-9|,|\.]/gi, "").split(",")
        if isNaN(position[0]) or isNaN(position[1]) then position = null
      else
        position = null

      @addResult
        fuel_type     : fuel_type
        id_province   : id_province
        province      : @_getText(tr.find("td:eq(0)"))
        location      : @_getText(tr.find("td:eq(1)"))
        address       : @_getText(tr.find("td:eq(2)"))
        margin        : @_getText(tr.find("td:eq(3)")).replace(/\s/g, '')
        date          : @_getText(tr.find("td:eq(4)"))
        price         : parseFloat(@_getText(tr.find("td:eq(5)")).replace(",", "."))
        gas_station   : @_getText(tr.find("td:eq(6)"))
        rem           : @_getText(tr.find("td:eq(8)"))
        schedule      : @_getText(tr.find("td:eq(9)"))
        position      : if position then [parseFloat(position[0]), parseFloat(position[1])] else []

    # check for pagination
    totalResults  = parseInt($("input[type=hidden]#inputLongitudTotal").val(), 10)
    if (currentPos + 10) < totalResults
      @queue "#{BASE_URL}&nomProvincia=#{id_province}&tipoCarburante=#{fuel_type}&posicion=#{currentPos + 10}", @parse

  onFinish: (results) ->
    tasks = (_saveResult(result) for result in results)
    Hope.join(tasks).then (error, result) ->
      console.log "Saved #{results.length} results"


_parseDate = (date) ->
  parts = date.split("/")
  return new Date("#{parts[2]}/#{parts[1]}/#{parts[0]}")

_saveResult = (data) -> ->
  promise = new Hope.Promise()
  Station.register({
    postal_code : data.id_province
    region      : data.province
    location    : data.location
    address     : data.address
    schedule    : data.schedule
    margin      : data.margin
    gas_station : data.gas_station
    geoposition : data.position
  }).then (error, station) ->
    if error then return promise.done error
    else
      Price.register({
        station   : station
        date      : _parseDate(data.date)
        price     : data.price
        active    : true
        fuel_type : data.fuel_type
      }).then (error, result) -> promise.done error, result
  promise


crawler = new Fuel()
console.log "Go!"
module.exports = -> crawler.start()

