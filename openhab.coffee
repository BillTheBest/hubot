# Description:
#   Openhab connector for local openhab instance http://www.openhab.org
#
# Dependencies:
#   None
#
# Configuration:
#   OPENHAB_URL
#
# Commands:
#   hubot value of <automation value>
#   hubot automation values
#
# Author:
#   ricktonoli
#
htmlparser = require("htmlparser")
select = require("soupselect").select

module.exports = (robot) ->
  robot.respond /value of (.*)/i, (msg) ->
     url = process.env.OPENHAB_URL
     query = (msg.match[1].split(/\s+/).map (word) -> word[0].toUpperCase() + word[1..-1]).join ' '
     robot.http("#{process.env.OPENHAB_URL}/rest/items/#{query}/state")
         .get() (err, res, body) ->
	      msg.send "#{body}"

  robot.respond /automation values/i, (msg) ->
    robot.http("#{process.env.OPENHAB_URL}/rest/items")
      .get() (err, resp, body) ->
        response = "Currently I know about:\r\n"
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
