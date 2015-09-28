onHeaders            = require 'on-headers'
{ MetricsBase }      = require 'koding-datadog'

module.exports = class MetricsMiddleware extends MetricsBase

  @prefix : 'nodejs.webserver'


  @sanitizeMetricName : (string) ->

    return string
      .replace /\/$/g,      'home'  # replace last / with home
      .replace /[\/-]/g,    '.'     # replace all / with .
      .replace /\.{2,}/g,   '.'     # remove adjacent dots


  @generateName : (req) ->

    path = switch
      when req.route.path is '*'  then req.path
      else                             req.route.path

    @sanitizeMetricName "#{@prefix}.#{path}"


  @populateTags : (req, res, tags) ->

    tags ?= []
    tags  = @populateCommonTags tags
    tags.push "http_method:#{req.method}"
    tags.push "http_response_code:#{res.statusCode}"

    return tags


  @metricsOnHeaders : (opts) ->

    return {
      increment         :
        'page_view'     : 1
      histogram         :
        'response_time' : opts.elapsedTime or 0
    }


  @send : (req, res, next) =>

    timer = new @timer

    onHeaders res, =>
      metricName  = @generateName(req)
      tags        = @populateTags req, res
      elapsedTime = timer.getElapsedTimeInMilliSecs()
      @sendMetrics @metricsOnHeaders({ elapsedTime }), metricName, tags

    next()

