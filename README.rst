
Netdata Plugin helper for Nim

Based on: https://github.com/firehol/netdata/wiki/External-Plugins

A plugin instance can create multiple charts. Each chart can have multiple
dimensions.

Charts and dimensions need to be created in order and before sending datapoints.

Usage:

.. code-block:: nim

   import netdata_plugin
   var p = newNetdataPlugin("myplugin")
   p.addChart("example", "random", "", "Random Numbers Stacked chart",
     "% of random numbers")
   p.addDimension("random1", "", ChartAlgorithm.percentage_of_absolute_row)
   p.addDimension("random2", "", ChartAlgorithm.incremental)
   p.addDimension("random3)
   p.sendChartDP("example", "random", {
     "random1": 1,
     "random2": 2,
     "random3": 3,
   })

Output:

.. code-block:: txt

 CHART example.random '' 'Random Numbers Stacked chart' '% of random numbers'
 DIMENSION random1 '' percentage-of-absolute-row 1 1
 DIMENSION random2 '' incremental 1 1
 DIMENSION random3 '' absolute 1 1
 BEGIN example.random
 SET random1 = 1
 SET random2 = 2
 SET random3 = 3
 END

The examples/ directory contains a plugin for the SDS011 particulate sensor
