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
#   hubot what is( the) <automation value>
#   hubot automation values (matching <x>)
#   hubot when I say <x> I mean <y>
#   hubot when I say <x> what do I mean
#   hubot set value of <x> to <y>
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

  robot.respond /what is( the)? (.*)/i, (msg) ->
    url = process.env.HUBOT_OPENHAB_URL
    lookup = whatimean.query msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_URL}/rest/items/#{lookup}/state")
      .get() (err, res, body) ->
        if (/404/i.test(body)) 
          msg.reply "Cannot find anything with the name #{lookup}."
        else 
          msg.reply "#{msg.match[2]} is currently #{body}"

  robot.respond /automation values( matching (.*))?/i, (msg) ->
    search = msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_URL}/rest/items")
      .get() (err, res, body) ->
        response = "Currently I know about:\r\n\r\n"
        handler = new htmlparser.DefaultHandler (error, dom) ->
          if (error || !dom)
            msg.reply "Error"
          else
            names = select(dom, "name")
            for name, position in names
#              msg.send "Checking for #{search} in #{name.children[0].data}"
              if ((search? && ((name.children[0].data.indexOf search, 0) > -1)) || !search?)
                response = response + name.children[0].data + '\r\n' 
            msg.reply response
        parser = new htmlparser.Parser(handler)
        parser.parseComplete(body)

  robot.respond /when I say (.+?) I mean (.+)/i, (msg) ->  
    msg.reply whatimean.add msg.match[1], msg.match[2]

  robot.respond /when I say (.+?) what do I mean/i, (msg) ->  
    msg.reply whatimean.query msg.match[1]

  robot.respond /set value of (.*) to (.*)/i, (msg) ->
    msg.reply "Setting #{msg.match[1]} to #{msg.match[2]}" 
    key = whatimean.query msg.match[1]
    value = whatimean.query msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_URL}/rest/items/#{key}/state")
      .put(value) (err, res, body) ->
    
