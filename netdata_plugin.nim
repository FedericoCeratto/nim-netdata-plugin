# 
#
## Netdata Plugin helper
##
## A plugin instance can create multiple charts. Each chart can have multiple
## dimensions.
##
## Charts and dimensions need to be created in order and before sending datapoints.
##
## Usage:
##
## .. code-block:: nim
##    import netdata_plugin
##    var p = newNetdataPlugin("myplugin")
##    p.addChart("example", "random", "", "Random Numbers Stacked chart",
##      "% of random numbers")
##    p.addDimension("random1", "", ChartAlgorithm.percentage_of_absolute_row)
##    p.addDimension("random2", "", ChartAlgorithm.incremental)
##    p.addDimension("random3)
##    p.sendChartDP("example", "random", {
##      "random1": 1,
##      "random2": 2,
##      "random3": 3,
##    })
##
## Output:
##
## .. code-block:: txt
##  CHART example.random '' 'Random Numbers Stacked chart' '% of random numbers'
##  DIMENSION random1 '' percentage-of-absolute-row 1 1
##  DIMENSION random2 '' incremental 1 1
##  DIMENSION random3 '' absolute 1 1
##  BEGIN example.random
##  SET random1 = 1
##  SET random2 = 2
##  SET random3 = 3
##  END


import os,
  ospaths,
  strutils

type
  NetdataPlugin* = ref object
    name*: string
    netdata_update_interval_s*: int
  ChartType* = enum
    line, area, stacked
  ChartAlgorithm* = enum
    absolute, incremental, percentage_of_absolute_row, percentage_of_incremental_row


proc newNetdataPlugin*(name: string): NetdataPlugin =
  if not existsEnv("NETDATA_UPDATE_EVERY"):
    raise newException(Exception, "The NETDATA_UPDATE_EVERY env variable is required")
  let netdata_update_interval_s = getEnv("NETDATA_UPDATE_EVERY").parseInt()
  NetdataPlugin(name: name, netdata_update_interval_s: netdata_update_interval_s)

proc createCacheDir(p: NetdataPlugin): string =
  ## Create a cache directory for the plugin, if needed.
  ## The directory lives under Netdata's cache dir and is persistent.
  if not existsEnv("NETDATA_CACHE_DIR"):
    raise newException(Exception, "The NETDATA_CACHE_DIR env variable is required")
  result = joinPath(getEnv("NETDATA_CACHE_DIR"), p.name)
  createDir(result)

proc getConfigDir(p: NetdataPlugin): string =
  ## Get Netdata config directory.
  ## Custom configuration for the plugin should live there.
  if not existsEnv("NETDATA_CONFIG_DIR"):
    raise newException(Exception, "The NETDATA_CONFIG_DIR env variable is required")
  result = getEnv("NETDATA_CONFIG_DIR")


proc addChart*(p: var NetdataPlugin, chtype, id, name, title, units: string,
    family="", context="", charttype=ChartType.line, priority=1000,
    update_every= -1, options="") =
  ## Create new chart.
  echo "CHART $#.$# '$#' '$#' '$#' " % [
    chtype, id, name, title, units, family, context, $charttype,
    $priority, $update_every, options
  ]

proc addDimension*(p: var NetdataPlugin, id: string, name="",
    algorithm=ChartAlgorithm.absolute, multiplier=1, divisor=1, hidden=false) =
  ## Add dimension to the chart. To be called right after `addChart`.
  let hidden_flag =
    if hidden: " hidden"
    else: ""
  let algo = replace($algorithm, "_", "-")
  echo "DIMENSION $# '$#' $# $# $# $#" % [id, name, algo, $multiplier, $divisor, $hidden_flag]


proc sendChartDP*(p: NetdataPlugin, chtype, id: string, data: openArray[(string, int)]) =
  ## Send datapoints for a chart. One or more dimensions can be passed.
  ##
  ## Example: sendChartDP("example", "random", {"random1": 1})
  echo "BEGIN $#.$#" % [chtype, id]
  for d in data:
    let (dimension, value) = d
    echo "SET $# = $#" % [dimension, $value]
  echo "END"

when isMainModule:
  # Demo
  var p = newNetdataPlugin("myplugin")
  p.addChart("example", "random", "", "Random Numbers Stacked chart",
    "% of random numbers")
  p.addDimension("random1", "", ChartAlgorithm.percentage_of_absolute_row)
  p.addDimension("random2", "", ChartAlgorithm.incremental)
  p.addDimension("random3")
  p.sendChartDP("example", "random", {
    "random1": 1,
    "random2": 2,
    "random3": 3,
  })
