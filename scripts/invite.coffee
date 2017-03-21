# Description:
#   Invite users to a GitHub organization team
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GITHUB_OAUTH - The GitHub OAuth token
#   HUBOT_GITHUB_ORGTEAM_INVITERS - The team ID of the users able to use the invite command
#   HUBOT_GITHUB_ORGNAME  - The organization name
#   GITHUB_NEWCOMERS_TEAM - The team ID of the newcomers team.
#   GITHUB_DEVELOPERS_TEAM - The team ID of the developers team.
#   GITHUB_MAINTAINERS_TEAM - The team ID of the maintainers team.
#
# Commands:
#   hubot (invite|inv) <username> [to [team]] - Allows maintainers to invite users to the gdg-vit organization.
#
# Author:
#   aalind0

gh_token = process.env.HUBOT_GITHUB_OAUTH
gh_inviter = process.env.HUBOT_GITHUB_ORGTEAM_INVITERS
gh_orgname = process.env.HUBOT_GITHUB_ORGNAME

module.exports = (robot) ->
  robot.respond /(?:invite|inv) @?([^\s]+)(?: to)?\s?(\w+)?/i, (msg) ->

    inviter = msg.message.user.login
    invitee = msg.match[1]
    if typeof msg.match[2] is 'string'
      invitee_team = msg.match[2]
    else
      invitee_team = 'newcomers'

    if invitee_team is "developers"
      gh_invitee = process.env.GITHUB_DEVELOPERS_TEAM
    else if invitee_team is "maintainers"
      gh_invitee = process.env.GITHUB_MAINTAINERS_TEAM
    else if invitee_team is "newcomers"
      gh_invitee = process.env.GITHUB_NEWCOMERS_TEAM
    else
      msg.send "**ERROR** Not a valid team name, select one from [maintainers, developers, newcomers]"
      msg.send "**SYNTAX** cobot invite <username> [to [team name]]"
      return

    robot.http("https://api.github.com/teams/#{gh_inviter}/members")
    .header('Authorization', "token #{gh_token}")
    .get() (err, res, tbody) ->
      if err
        msg.send "Oh no! Error getting the inviter list: #{err}"
        return

      if res.statusCode isnt 200
        msg.send "Team list error: HTTP #{res.statusCode}"
      body = JSON.parse tbody

      for i in body
        maintainers = (user.login for user in body)

      if inviter not in maintainers
        msg.send "Nice try. :poop:"
        return

      robot.http("https://api.github.com/teams/#{gh_invitee}/memberships/#{invitee}")
      .header('Authorization', "token #{gh_token}")
      .put() (err, res, tbody) ->
        if err
          msg.send "Oh no! Error inviting the user: #{err}"
          return

        if res.statusCode isnt 200
          msg.send "Invite error: HTTP #{res.statusCode} :worried:"
          return
        if invitee_team is "newcomers"
          msg.send "Welcome @#{invitee}! :tada:\n\nYou will have to work hard and most likely become a better coder than you are now just as we all did.\n\nDon't get us wrong: we are *very* glad to have you with us on this journey! We will also be there for you at all times to help you with actual problems. :)"
        else if invitee_team is "maintainers"
          msg.send "@#{invitee} you seem to be awesome! You are a maintainer! :tada:"
        else if invitee_team is "developers"
          msg.send "Wow @#{invitee}, you are a part of developers team now! :tada: Welcome to our community!"
        else
          msg.send "Something went seriously wrong :worried: - I guess someone should check the logs."
