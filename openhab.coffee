# Description:
#   Openhab connector for local openhab instance http://www.openhab.org
#   Allows for adding "translation" text to allow for better referencing of values.
#   Using "when I say <x> I mean <y>" allows you then to query with "what is <x>" OR "what is <y>"
#
# Dependencies:
#   redis-brain.coffee
#
# Configuration:
#   HUBOT_OPENHAB_INTERNAL_URL - the internal URL to use for openhab
#   HUBOT_OPENHAB_EXTERNAL_URL - the external URL to use for openhab
#   OPENHAB_USER - the auth user to use to access openhab
#   OPENHAB_PASSWORD - the auth user's password to use to access openhab
#
# Commands:
#   hubot what is( the) <openhab value> - returns an openhab value
#   hubot automation values (matching <x>) - returns a list of all openhab lookup options
#   hubot when I say <x> I mean <y> - translate x to y when using "what is"
#   hubot when I say <x> what do I mean
#   hubot set value of <x> to <y> - sets openhab value x to y
#   hubot let me know when <x> is( above|equal to|below) <y> - monitor a value and notify
#   hubot graph me <openhab value> for <period> - graph a value for a period (h,4h,8h,12h,D,3D,W,2W,M,2M,4M,Y)
#
# Author:
#   Rick Tonoli <rick@tonoli.co.nz>
#

htmlparser = require("htmlparser")
select = require("soupselect").select
cronJob = require('cron').CronJob

module.exports = (robot) ->

  user = process.env.OPENHAB_USER
  pass = process.env.OPENHAB_PASSWORD
  auth = 'Basic ' + new Buffer(user + ':' + pass).toString('base64');

  robot.brain.on 'loaded', =>
    robot.brain.data.openhab ?= {}
#    robot.logger.info "Loading #{Object.keys(robot.brain.data.openhab).length} items from OpenHAB knowledge"

  add = (key, value) ->
    robot.brain.data.openhab[key] = value
#    robot.logger.info "OpenHAB key added, now at #{Object.keys(robot.brain.data.openhab).length} items"
    "Ok, when you say #{key} you mean #{value}"

  query = (key) ->
    robot.brain.data.openhab[key] or key

  robot.respond /what is( the)? (.*)/i, (msg) ->
    url = process.env.HUBOT_OPENHAB_INTERNAL_URL
    lookup = query msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_INTERNAL_URL}/rest/items/#{lookup}/state")
      .get() (err, res, body) ->
        if (/404/i.test(body)) 
          msg.reply "Cannot find anything with the name #{lookup}."
        else 
          msg.reply "#{msg.match[2]} is currently #{body}"

  robot.respond /automation values( matching (.*))?/i, (msg) ->
    search = msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_INTERNAL_URL}/rest/items")
      .get() (err, res, body) ->
        response = "Currently I know about:\r\n\r\n"
        handler = new htmlparser.DefaultHandler (error, dom) ->
          if (error || !dom)
            msg.reply "Error"
          else
            names = select(dom, "name")
            for name, position in names
              if ((search? && ((name.children[0].data.indexOf search, 0) > -1)) || !search?)
                response = response + name.children[0].data + '\r\n' 
            msg.reply response
        parser = new htmlparser.Parser(handler)
        parser.parseComplete(body)

  robot.respond /when I say (.+?) I mean (.+)/i, (msg) ->  
    msg.reply add msg.match[1], msg.match[2]

  robot.respond /when I say (.+?) what do I mean/i, (msg) ->  
    msg.reply query msg.match[1]

  robot.respond /set value of (.*) to (.*)/i, (msg) ->
    msg.reply "Setting #{msg.match[1]} to #{msg.match[2]}" 
    key = query msg.match[1]
    value = query msg.match[2]
    robot.http("#{process.env.HUBOT_OPENHAB_INTERNAL_URL}/rest/items/#{key}/state")
      .put(value) (err, res, body) ->

  robot.respond /graph me (.*) for (h|4h|8h|12h|D|3D|W|2W|M|2M|4M|Y)/i, (msg) ->
    lookup = query msg.match[1]
    period = query msg.match[2]
    url = "#{process.env.HUBOT_OPENHAB_EXTERNAL_URL}/chart?items=#{lookup}&period=#{period}"
    msg.send "#{url}&type=.png"

  robot.respond /let me know when (.*) is (above|below|equal to) (.*)/i, (msg) ->
    lookup = msg.match[1]    
    comparator = msg.match[2]    
    value = msg.match[3]    
    cronPattern = "0 * * * * *"

    robot.logger.info "Creating the cron job..."

    cron = new cronJob(cronPattern, =>
      robot.logger.info "Starting cron job"
      check robot
    )
    cron.start()
   
  check: (robot) ->
    robot.http("#{process.env.HUBOT_OPENHAB_INTERNAL_URL}/rest/items/#{lookup}/state")
      .get() (err, res, body) ->
        actual = body
        robot.logger.info "Got response for #{lookup} of #{actual}, comparator is #{comparator}, value is #{value}"
        sendit = switch
          when comparator is "above" && value > actual then sendmessage robot
          when comparator is "equal to" && value == actual then sendmessage robot
          when comparator is "below" && value < actual then sendmessage robot
        robot.send "Done."
    
   sendmessage: (robot) ->
     robot.send "Value of #{lookup} is #{actual} which is above #{value}"
    
