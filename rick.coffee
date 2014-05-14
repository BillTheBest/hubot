# Description:
#   General stuff for debugging etc.
#
# Dependencies:
#   redis-brain.coffee
#
# Configuration:
#
# Commands:
#   hubot braindump - dump the contents of the brain
#
# Author:
#   Rick Tonoli <rick@tonoli.co.za>
#

module.exports = (robot) ->
  robot.respond /braindump/i, (msg) ->
    msg.send JSON.stringify(robot.brain.data)    
