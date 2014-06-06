# Description:
#   Openhab connector for local openhab instance http://www.openhab.org
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
#   hubot what is the <x> - returns an openhab value
#   hubot automation values <matching <x>> - returns a list of all openhab lookup options with optional match search
#   hubot when I say <x> I mean <y> - translate x to y when using "what is"
#   hubot when I say <x> what do I mean
#   hubot set value of <x> to <y> - sets openhab value x to y
#   hubot I want to know when <x> is <above,below,equal to> <y> <once,forever> checking every <number> <second(s),minute(s),hour(s)>
#   hubot I don(')t want to know about <x> - stop monitoring <x>, use "anything" to remove all
#   hubot what do I want to know about - list all monitored things
#   hubot graph me <openhab value> for <period> - graph a value for a period (h,4h,8h,12h,D,3D,W,2W,M,2M,4M,Y)
#
# Author:
#   Rick Tonoli <rick@tonoli.co.nz>
#

htmlparser = require("htmlparser")
select = require("soupselect").select
cronJob = require("cron").CronJob
jobs = {}

module.exports = (robot) ->

  user = process.env.OPENHAB_USER
  pass = process.env.OPENHAB_PASSWORD
  auth = 'Basic ' + new Buffer(user + ':' + pass).toString('base64');

  robot.brain.on 'loaded', =>
    robot.brain.data.openhab ?= {}
    robot.brain.data.openhab.job ?= {}
#    robot.brain.data.openhab.job = {}
    for own id, job of robot.brain.data.openhab.job
      job = new Job(id, job[0].cronPattern, job[0].user, job[0].lookup, job[0].comparator, job[0].value, job[0].repeat)
      job.start(robot)
      jobs[id] = job
 
  add = (key, value) ->
    robot.brain.data.openhab[key] = value
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
      .headers(Authorization: auth)
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
    lookup = []    
    (msg.match[1].split ",").every (item) ->
      item = item.replace /^\s+|\s+$/g, ""
      lookup.push "#{query item}"
    period = query msg.match[2]
    url = "#{process.env.HUBOT_OPENHAB_EXTERNAL_URL}/chart?items=#{lookup.toString()}&period=#{period}&type=.png" 
    msg.http(url)
      .headers(Authorization: auth)
      .get() (err, res, body) ->
        msg.reply "#{url}"

  robot.respond /(I want to know|let me know) when (.*) is (above|below|equal to) (.*) (once|forever) checking every (\d+) (second(s)?|minute(s)?|hour(s)?)/i, (msg) ->
    lookup = msg.match[2]
    comparator = msg.match[3]    
    value = msg.match[4]
    repetition = msg.match[5]
    interval = msg.match[6]
    intervalType = msg.match[7]
#    for i in [0..7] by 1
#      robot.logger.info msg.match[i]

    cronPattern = switch intervalType
      when "second" then "*/#{interval} * * * * *"
      when "seconds" then "*/#{interval} * * * * *"
      when "minute" then "0 */#{interval} * * * *"
      when "minutes" then "0 */#{interval} * * * *"
      when "hour" then "0 0 */#{interval} * * *"
      when "hours" then "0 0 */#{interval} * * *"
     
    id = Math.floor(Math.random() * 1000000) while !id? || jobs[id]
    user = msg.message.user
    user = user.user if "user" of user
    job = new Job(id, cronPattern, user, lookup, comparator, value, repetition)
    job.start(robot)
    jobs[id] = job
    robot.brain.data.openhab.job[id] = job.serialize()
    msg.send "Ok, I'll let you know when #{lookup} is #{comparator} #{value}."

  robot.respond /I don(')?t want to know about (.*)/i, (msg) ->
    lookup = msg.match[2]
    for own id, job of robot.brain.data.openhab.job
      if (job[0].lookup is lookup) or lookup is "anything"
        delete robot.brain.data.openhab.job[id]
        if jobs[id]
          jobs[id].stop()
          delete jobs[id]
        msg.send "Notification deleted"

  robot.respond /what do I want to know about/i, (msg) ->
    for own id, job of robot.brain.data.openhab.job
      msg.send "#{job[0].lookup} #{job[0].comparator} #{job[0].value}"


class Job
  constructor: (id, pattern, user, lookup, comparator, value, repeat) ->
    clonedUser = {}
    clonedUser[k] = v for k,v of user
    @id = id
    @pattern = pattern
    @user = clonedUser
    @lookup = lookup
    @comparator = comparator
    @value = value
    @repeat = repeat

  start: (robot) ->
    
    lookupvalue = robot.brain.data.openhab[@lookup] or @lookup

    @cronjob = new cronJob(@pattern, =>
      robot.http("#{process.env.HUBOT_OPENHAB_INTERNAL_URL}/rest/items/#{@lookup}/state")
        .headers("lookup":lookupvalue, "comparator":@comparator, "value":@value, "inuser":@user, "repeat":@repeat, "id":@id, "job":this)
        .get() (err, res, body) ->
          actual = body.replace /^\s+|\s+$/g, ""
          
          lookup = res.req._headers["lookup"]
          if !isNaN(parseInt(res.req._headers["lookup"]))
            lookup = +lookup          
          value = res.req._headers["value"].replace /^\s+|\s+$/g, ""
          if !isNaN(parseInt(res.req._headers["value"].replace /^\s+|\s+$/g, ""))
            value = +value
          comparator = res.req._headers["comparator"]
          inuser = res.req._headers["inuser"]
          repetition = res.req._headers["repeat"]
          job = res.req._headers["job"]
          envelope = user: inuser

          if (comparator is "above" && actual > value)
            robot.send envelope, "Value of #{lookup} is #{actual} which is above #{value}"
            if (repetition is "once")
              id = res.req._headers["id"]
              delete robot.brain.data.openhab.job[id]
              robot.logger.info job
              job.stop()
              robot.logger.info "Job deleted"
          if (comparator is "equal to" && value is actual)
            robot.send envelope, "Value of #{lookup} is #{actual} which is equal to #{value}"
            if (repetition is "once")
              id = res.req._headers["id"]
              delete robot.brain.data.openhab.job[id]
              robot.logger.info job
              job.stop()
              robot.logger.info "Job deleted"
          if (comparator is "below" && actual < value)
            robot.send envelope, "Value of #{lookup} is #{actual} which is below #{value}"
            if (repetition is "once")
              id = res.req._headers["id"]
              delete robot.brain.data.openhab.job[id]
              robot.logger.info job
              job.stop()
              robot.logger.info "Job deleted"
    )
    @cronjob.start()

  stop: ->
    @cronjob.stop()

  serialize: ->
    ["pattern":@pattern, "user":@user, "lookup":@lookup, "comparator":@comparator, "value":@value, "repeat":@repeat]

