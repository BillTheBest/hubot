# Description:
#   Openhab connector for local openhab instance http://www.openhab.org
#   Allows for adding "translation" text to allow for better referencing of values.
#   Using "when I say <x> I mean <y>" allows you then to query with "what is <x>" OR "what is <y>"
#
# Dependencies:
#   redis-brain.coffee
#
# Configuration:
#   HUBOT_OPENHAB_URL
#
# Commands:
#   hubot what is <automation value>
#   hubot automation values
#   hubot when I say <key> I mean <value>
#
# Author:
#   Rick Tonoli <rick@tonoli.co.za>
#

htmlparser = require("htmlparser")
select = require("soupselect").select

class WhatIMean
  constructor: (@robot) ->
    @robot.brain.on 'loaded', =>
      if (!@robot.brain.data.openhab?)
        @robot.brain.data.openhab = []
#      @robot.logger.info "Loading #{Object.keys(@robot.brain.data.openhab).length} items from OpenHAB whatimean knowledge"

  add: (key, value) ->
    @robot.brain.data.openhab[key] = value
#    @robot.logger.info "OpenHAB key added, now at #{Object.keys(@robot.brain.data.openhab).length} items"
    "Ok, when you say #{key} you mean #{value}"

  query: (key) ->
    @robot.brain.data.openhab[key] or key

module.exports = (robot) ->

  whatimean = new WhatIMean robot

  robot.respond /what is (.*)/i, (msg) ->
     url = process.env.HUBOT_OPENHAB_URL
     lookup = whatimean.query msg.match[1]
     robot.http("#{process.env.OPENHAB_URL}/rest/items/#{lookup}/state")
         .get() (err, res, body) ->
              msg.send "The value is currently #{body}"

  robot.respond /automation values/i, (msg) ->
    robot.http("#{process.env.HUBOT_OPENHAB_URL}/rest/items")
      .get() (err, resp, body) ->
        response = "Currently I know about:\r\n\r\n"
        handler = new htmlparser.DefaultHandler (error, dom) ->
          if (error || !dom)
            msg.send "Error"
          else
            names = select(dom, "name")
            for name, position in names
               response = response + name.children[0].data + '\r\n'
            msg.send response
        parser = new htmlparser.Parser(handler)
        parser.parseComplete(body)

  robot.respond /when I say (.+?) I mean (.+)/i, (msg) ->
     msg.reply whatimean.add msg.match[1], msg.match[2]

  robot.respond /when I say (.+?) what do I mean/i, (msg) ->
     msg.reply whatimean.query msg.match[1]


