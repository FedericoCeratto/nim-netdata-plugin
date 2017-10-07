#
#
## SDS011 Laser PM2.5 and PM10 Sensor

import os,
  serial,
  sequtils,
  strutils,
  streams

import netdata_plugin


const
  USBPORT  = "/dev/ttyUSB0"

proc main() =

  var p = newNetdataPlugin("SDS011")
  p.addChart("particulate", "pm", "", "Particulate", "ppm")
  p.addDimension("PM25")
  p.addDimension("PM10")
  #p.send_one("particulate", "PM25", 3)

  let sensor = newSerialStream(USBPORT, 9600, Parity.None, 8, StopBits.One, Handshake.None, buffered=true)
  defer: close sensor

  while true:
    sleep 100
    if readChar(sensor) != '\xAA':
      continue

    if readChar(sensor) != '\xC0':
      continue

    let
      pm2_h = readInt8 sensor
      pm2_l = readInt8 sensor
      pm10_h = readInt8 sensor
      pm10_l = readInt8 sensor

      pm2 = pm2_h + pm2_l * 256
      pm10 = pm10_h + pm10_l * 256

    p.sendChartDP("particulate", "pm", {
      "PM25": pm2,
      "PM10": pm10,
    })


main()
