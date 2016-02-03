# Description:
#   Get a stock price
#
# Dependencies:
#   moment
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

DEBUG = true

moment = require("moment-timezone")
cheerio = require("cheerio")
ellipsize = require("ellipsize")

parsePriceLine = (line_string,date_offset,interval) ->
  #line format: DATE,CLOSE,HIGH,LOW,OPEN,VOLUME
  chunks = line_string.split(',')
  if chunks[0][0] == 'a'
    date = moment(parseInt(chunks[0].substring(1))*1000)
  else
    date = moment(date_offset).add(parseInt(chunks[0]) * interval)
  ret =
    moment: date
    close: parseFloat(chunks[1])
    high: parseFloat(chunks[2])
    low: parseFloat(chunks[3])
    open: parseFloat(chunks[4])
    volume: parseFloat(chunks[5])
  return ret

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
       time_start = moment().subtract(num,'days').startOf('day') #get the start of the first day in the range
       if num <= 5
         interval_for_prices = 300
       else
         interval_for_prices = 86400
    if unit == "m"
       seconds = 2592000  # 60 * 60 * 24 * 30
       unit = "M"
       time_start = moment().subtract(num,'months').startOf('month') #get the start of the first month in the range
       interval_for_prices = 86400
    if unit == "y"
       seconds = 31536000  # 60 * 60 * 24 * 365
       unit = "Y"
       time_start = moment().subtract(num,'years') #DONT get the start of the year.
       interval_for_prices = 86400

    seconds *= num
    interval = Math.round seconds / 24 / 30


    # Fetch basic info
    msg.http('https://finance.google.com/finance/info?client=ig&q=' + ticker)
      .get() (err, res, body) ->
        chart_image = "https://www.google.com/finance/getchart?q=#{ticker}&p=#{num}#{unit}&i=#{interval}"

        result = JSON.parse(body.replace(/\/\/ /, ''))?[0]
        if result
          [price, change, pctChange] = [result.l_cur, result.c, result.cp]
          pctChange = parseFloat pctChange

        # Now fetch the historical price charts to get the percent change (and change) for the specified time interval
        ts = time_start.valueOf()
        prices_url = "https://www.google.com/finance/getprices?q=#{ticker}&i=#{interval_for_prices}&p=#{num}#{unit}&f=d,c,v,o,h,l&df=cpct&auto=1&ts=#{ts}"
        if DEBUG
          console.log prices_url
        msg.http(prices_url)
          .get() (err, res, body) ->
            # only update if we are not 1d.
            if !(unit == "d" && num == 1)
              result = body.split("\n")
              first_price_line = parsePriceLine(result[7])
              last_price_line = parsePriceLine(result[result.length-2])
              start = first_price_line.close
              end = last_price_line.close
              if DEBUG
                first_price_line.moment = first_price_line.moment.tz("America/Los_Angeles").format("dddd, MMMM Do YYYY, h:mm:ss a ZZ")
                last_price_line.moment = last_price_line.moment.tz("America/Los_Angeles").format("dddd, MMMM Do YYYY, h:mm:ss a ZZ")
                console.log first_price_line, last_price_line
                console.log "Changing change from " + change + " to " + (end-start).toFixed(2)
                console.log "Changing pctChange from " + pctChange + " to " + ((end-start) * 100/ start).toFixed(2)
              change = (end-start).toFixed(2)
              pctChange = (change * 100 / start).toFixed(2)

            # Fetch company name and description
            msg.http("https://www.google.com/finance?q="+ticker)
              .get() (err, res, body) ->
                $ = cheerio.load(body)
                company_name = $("#sharebox-data meta[itemprop=name]").attr("content") || 'No company name'
                company_description = $(".companySummary").text().trim() || 'No description'

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

                fields = []
                fields.push
                  title: "Change"
                  value: "#{change} (#{pctChangeText})"
                  short: true

                fields.push
                  title: "Price"
                  value: "#{price}"
                  short: true

                payload =
                  message: msg.message
                  content:
                    title: company_name
                    title_link: "https://www.google.com/finance?q="+ticker
                    image_url: chart_image
                    fallback_text: text.join " "
                    color: "#aaaaaa"
                    #fields: fields
                    text: ellipsize(company_description,200) + text.join " "
                    mrkdwn_in: ["text"]
                robot.emit "slack.attachment", payload


  robot.respond regex, responder
  robot.hear new RegExp('\\.' + regex.source, 'i'), responder
