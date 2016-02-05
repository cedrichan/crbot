# Description:
#   Generator for awyisser images
#
# Configuration:
#   HUBOT_AWYISSER_SFW=true for safe for work mode
#
# Commands:
#   hubot awyiss <phrase>: generate awyisser image for <phrase>
#   hubot awyiss motha fuckin <phrase>: generate awyisser image for <phrase>

module.exports = (robot) ->
  robot.respond /(aw *yiss)( motha fuckin)? (.*)/i, (msg) ->
    awyisser msg, msg.match[3]

awyisser = (msg, phrase) ->
  if phrase.length > 40
    msg.send "aw nooo... your phrase is too long! (40 chars max)"
    return

  sfw = process.env.HUBOT_AWYISSER_SFW == 'true' ? 'true' : 'false'

  url = 'http://awyisser.com/api/generator'
  msg.http(url)
    .header('Content-Type', 'application/json')
    .header('Accept', 'application/json')
    .post(JSON.stringify({ phrase, sfw })) (err, res, body) ->
      switch res.statusCode
        when 200
          msg.send JSON.parse(body).link
        else
          msg.send "aw nooo... couldn't connect to awyisser"
