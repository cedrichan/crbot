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
#   hubot stock [info|quote|price] [for|me] <ticker> [1d|5d|2w|1mon|1y] - Get a stock price
#
# Author:
#   eliperkins
#   maddox   
#   johnwyles

module.exports = (robot) ->
  regex = /stock (?:info|price|quote)?\s?(?:for|me)?\s?@?([A-Za-z0-9.-_]+)\s?(\d+\w+)?/i
  responder = (msg) ->
    ticker = escape(msg.match[1])
    time = msg.match[2] || '1d'
    msg.http('http://finance.google.com/finance/info?client=ig&q=' + ticker)
      .get() (err, res, body) ->
        msg.send "http://chart.finance.yahoo.com/z?s=#{ticker}&t=#{time}&q=l&l=on&z=l&a=v&p=s&lang=en-US&region=US#.png"
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
