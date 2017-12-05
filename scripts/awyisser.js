// Description:
//   Generator for awyisser images
//
// Configuration:
//   HUBOT_AWYISSER_SFW=true for safe for work mode
//
// Commands:
//   hubot awyiss <phrase>: generate awyisser image for <phrase>
//   hubot awyiss motha fuckin <phrase>: generate awyisser image for <phrase>

module.exports = function(robot) {
  robot.respond(/(aw *yiss)( motha fuckin)? (.+)/i, msg => awyisser(msg, msg.match[3]));
  robot.hear(/\.(?:aw)?yiss (.+)/i, msg => awyisser(msg, msg.match[1]));
};

var awyisser = function(msg, phrase) {
  if (phrase.length > 40) {
    msg.send("aw nooo... your phrase is too long! (40 chars max)");
  }

  const sfw = (process.env.HUBOT_AWYISSER_SFW === 'true');
  const url = 'http://awyisser.com/api/generator';
  msg.http(url)
    .header('Content-Type', 'application/json')
    .header('Accept', 'application/json')
    .post(JSON.stringify({ phrase, sfw }))(function(err, res, body) {
      switch (res.statusCode) {
        case 200:
          msg.send(JSON.parse(body).link);
          break;
        default:
          msg.send(`aw nooo... couldn't connect to awyisser (${res.statusCode})`);
      }
  });
};
