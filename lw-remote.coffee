"use strict"

net = require "net"
dgram = require "dgram"
opener = require "openurl"
inquirer = require "inquirer"

REMOTE_BASE_URL = "https://shell.cerevo.com/remote/auth/"
IP_INPUT_QUERY =
  type: "input"
  name: "address"
  message: "Cerevo LiveWedge IP Address"
UDP_CONNECT_COMMAND = new Buffer [0x21, 0x00, 0x00, 0x00]

parseString = (bytes) ->
  str = ""
  for char in bytes
    break if char == 0
    str += String.fromCharCode(char)
  str

inquirer.prompt [IP_INPUT_QUERY], (answers) ->
  udp = dgram.createSocket "udp4"
  tcp = new net.Socket

  tcp.connect 8888, answers.address, ->
    console.log "[1/3] Connected Cerevo LiveWedge"
    udp.send UDP_CONNECT_COMMAND, 0, UDP_CONNECT_COMMAND.length, 8888, answers.address
    setTimeout ->
      console.log "[2/3] Request auth key and start streaming..."
      # REQUEST AUTH KEY
      tcp.write new Buffer [0x08, 0x00, 0x00, 0x00]
      # START ENCORDING
      tcp.write new Buffer [0x12, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]
    , 1000

  tcp.on "error", (error) ->
    console.log "ERROR", error

  tcp.on "data", (data) ->
    switch data[0]
      when 0x13 # RETURN AUTH KEY
        console.log "[3/3] Got auth key!"
        auth_key = parseString data[4..25]
        if auth_key == ""
          console.log "Missed to get auth key!"
        else
          url = "#{REMOTE_BASE_URL}#{auth_key}"
          console.log "Remote dashboard url: #{url}"
          opener.open url
        tcp.end()
        udp.close()
