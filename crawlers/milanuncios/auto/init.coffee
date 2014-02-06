BaseCrawler   = require "../../../common/base"
Hope          = require "hope"
ResultModel   = require "./models/result"

DOMAIN = "http://www.milanuncios.com/"
BASE = "coches-de-segunda-mano/"

FUEL_TYPES =
  GASOLINA  : 0
  DIESEL    : 1


CURRENT_PAGE = 1
LAST_DATABASE_REFS = null


class MilAnunciosCars extends BaseCrawler

  name      : "MilAnuncios (coches)"

  custom_results   : {}
  invalid_results  : 0

  current_page: CURRENT_PAGE
  PROVIDER:
    MILANUNCIOS: 1

  startUrls : ["#{DOMAIN}#{BASE}?pagina=#{CURRENT_PAGE}"]

  parse: (error, response, $) =>
    check_next_page = true
    has_next_page = $("table").last().find("td").last().attr("onclick")
    $("#cuerpo > .x1").each (i, item) =>
      if check_next_page
        item = $ item
        renewed = item.find("[href='/creditos/auto-renueva.php']").length > 0
        unless renewed
          ref = _parseText(item.children(".x2").find(".x5")).substring(1)
          if ref in LAST_DATABASE_REFS
            check_next_page = false
            console.log "FOUND !!!!!"
            return

          url = item.find(".cti").attr "href"
          if url.substring(0, 1) is "/" then url = DOMAIN + url.substring(1)
          else url = DOMAIN + BASE + url
          @queue url, @parseCar

    # Next Page
    if check_next_page and has_next_page
      @current_page++
      @queue DOMAIN + BASE + "?pagina=#{@current_page}"

  parseCar: (error, response, $) =>
    result = {}
    title = $(".pagAnuTituloBox a").html()
    title_parts = title.split(" - ")
    if title_parts.length > 1
      result.provider = @PROVIDER.MILANUNCIOS
      result.url = response.request.uri.href
      result.reference = _parseText $(".anuRefBox b")
      result.make = title_parts[0].toLowerCase().trim()
      model = title_parts[1].toLowerCase().trim()
      result.model = title_parts[1].toLowerCase().trim()
      result.version = "?"
      result.description = _parseText $(".pagAnuCuerpoAnu")
      result.fuel_type = FUEL_TYPES[_parseText($(".gas,.die")).toUpperCase()]
      result.year = _parseNumber $(".ano")
      result.kms = _parseNumber $(".kms")
      result.price = _parseNumber $(".pr")
      result.images = []
      $(".pagAnuFotoBox img").map -> result.images.push $(@).attr "src"
      @custom_results[result.reference] = result
      @queue "#{DOMAIN}datos-contacto/?id=#{result.reference}", @parseContact
    else @invalid_results++


  parseContact: (error, response, $) =>
    reference = response.request.uri.href.split("=")[1]
    if $(".nombreTienda").length
      name = _parseText $(".nombreTienda")
      contact_type = "SHOP"
    else
      name = _parseText $(".texto > div").first()
      contact_type = "PARTICULAR"

    @custom_results[reference].contact =
      name        : name
      type        : contact_type
      telephones  : _getTelephoneNumbers($(".texto script"))
      address     : _parseText($(".direcciontienda")).replace("Dirección: ", "")


  onFinish: =>
    results = []
    results.push(data) for ref, data of @custom_results
    console.log "\n\n"
    console.log "=========================================="
    console.log results
    console.log "Results found          :: ", results.length
    console.log "Invalid results found  :: ", @invalid_results
    console.log "TOTAL results          :: ", results.length + @invalid_results

    ResultModel.saveAll(results).then (error, result) ->
      console.log "All saved !!"
      console.log "=========================================="
      console.log "\n\n"


crawler = new MilAnunciosCars()



ResultModel.searchLastReferences().then (error, references) ->
  LAST_DATABASE_REFS = references
  crawler.start()


module.exports = ->
  ResultModel.searchLastReferences().then (error, references) ->
    LAST_DATABASE_REFS = references
    crawler.start()



_getTelephoneNumbers = (tel_elements) ->
  telephones = []
  tel_elements.each (i, tel) ->
    regexp = new RegExp("'.*'", "gi")
    if result = tel.innerHTML.match(regexp)
      unescaped = unescape(result[0].replace(/'/g, ''))
      telephones.push parseInt(unescaped.replace(/(<([^>]+)>)/ig, '').trim())
  telephones

_parseText = (el) ->
  el.text().replace(/\n/g, ' ').replace(/\ +/g, ' ').trim()

_parseNumber = (el) ->
  n = parseInt(el.text().replace(".", ""))
  if isNaN(n) then null else n

