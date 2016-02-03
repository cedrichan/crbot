# Description:
#   Get a stock price
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot stock [info|quote|price] [for|me] <ticker> [1d|5d|1m|1y] - Get a stock price
#
# Author:
#   eliperkins
#   maddox   
#   johnwyles

module.exports = (robot) ->
  regex = /stock (?:info|price|quote)?\s?(?:for|me)?\s?@?([A-Za-z0-9.-_]+)\s?((\d+)([dmy]))?/i
  responder = (msg) ->
    ticker = escape(msg.match[1]).toUpperCase()

    # Parse out the chart duration.
    num = msg.match[3] * 1 || 1
    unit = (msg.match[4] || 'd').toLowerCase()

    # Normalize the strings to fit the Google Finance query params.
    # Also calculate the number of seconds in the query, this is used to
    # determine the interval widths for the query.
    if unit == "d"
       seconds = 86400  # 60 * 60 * 24
    if unit == "m"
       seconds = 2592000  # 60 * 60 * 24 * 30
       unit = "M"
    if unit == "y"
       seconds = 31536000  # 60 * 60 * 24 * 365
       unit = "Y"

    seconds *= num
    interval = Math.round seconds / 24 / 30

    msg.http('https://finance.google.com/finance/info?client=ig&q=' + ticker)
      .get() (err, res, body) ->
        msg.send "https://www.google.com/finance/getchart?q=#{ticker}&p=#{num}#{unit}&i=#{interval}"
        result = JSON.parse(body.replace(/\/\/ /, ''))?[0]
        if result
          [price, change, pctChange] = [result.l_cur, result.c, result.cp]
          pctChange = parseFloat pctChange
          if pctChange >= 0
            pctChangeText = "+#{pctChange}"
          else
            pctChangeText = "#{pctChange}"
          pctChangeText += "%"
          text = ["*#{price}*", "(#{change} #{pctChangeText})"]
          
          if pctChange >= 0.5 then text.push ":chart_with_upwards_trend:"
          if pctChange >= 2 then text.push ":fire:"
          if pctChange >= 10 then text.push ":rocket:"
          if pctChange <= -0.5 then text.push ":chart_with_downwards_trend:"
          if pctChange <= -2 then text.push ":bomb:"
          if pctChange <= -10 then text.push ":poop:"

          msg.send text.join " "

  robot.respond regex, responder
  robot.hear new RegExp('\\.' + regex.source, 'i'), responder
