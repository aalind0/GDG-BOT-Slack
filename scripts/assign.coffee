# Description:
#   Allows users to assign themselves to github issues across all gdgvit repos
#
# Commands:
#   hubot assign <issue_link> - Assigns issue <issue_link> to user
#   hubot unassign <issue_link> - Unassign the user from the issue <issue_link>
#
# Configuration:
#   HUBOT_GITHUB_OAUTH
#
# Author:
#   Aalind Singh (@aalind0)

gh_token = process.env.HUBOT_GITHUB_OAUTH

module.exports = (robot) ->
  robot.respond /assign (https:\/\/github.com\/gdgvit\/([^\/]+)\/issues\/(\d+))/i, (msg) ->
    repo = msg.match[2]
    issueNumber = msg.match[3]
    assignee_requester = msg.message.user.login

    robot.http("https://api.github.com/repos/gdgvit/#{repo}/issues/#{issueNumber}")
          .get() (err, res, body) ->
            if err
              console.log("Error : #{err}")
              msg.send "Error occured while checking the assignee of that issue."
            if JSON.parse(body)["assignee"] is null # Check if the issue already has an assignee
              # Check if issue is a newcomer issue
              if "difficulty/newcomer" in (label.name for label in JSON.parse(body)['labels'])
                robot.http("https://api.github.com/search/issues?q=is:issue%20user:gdgvit%20assignee:#{assignee_requester}")
                  .get() (err, res, body) ->
                    if err
                      console.log("Error : #{err}")
                      msg.send "Error while checking for other issues assigned to you."
                    if JSON.parse(body)['total_count'] > 0
                      msg.send "You already did a newcomer issue. Move on to low difficulty issues now - you can do it! Please leave the others for the real newcomers or ask a GDG-VIT maintainer if it's important."
                    else
                      assign(":tada: Good one! You're one step further towards becoming a full-fledged developer.")
              else
                assign(":tada: You have been assigned to #{msg.match[1]}")
            else
              msg.send "Issue already assigned to someone, please lookout for other [issues](https://github.com/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+user%3Agdgvit)"
      assign = (message) ->
        robot.http("https://api.github.com/repos/gdgvit/#{repo}/issues/#{issueNumber}/assignees")
          .header('Authorization', "token #{gh_token}")
          .post(JSON.stringify({assignees: [assignee_requester]})) (err, res, body) ->
            if res.statusCode is not 201 or err
              if err is not undefined
                msg.send "Assigning failed :( #{err}"
              else
                msg.send "Assigning failed :( #{res.statusCode}"
            else
              msg.send message

  robot.respond /unassign (https:\/\/github.com\/gdgvit\/([^\/]+)\/issues\/(\d+))/i, (msg) ->
    repo = msg.match[2]
    issueNumber = msg.match[3]
    unassignee_requester = msg.message.user.login
    robot.http("https://api.github.com/repos/gdgvit/#{repo}/issues/#{issueNumber}/assignees")
      .header('Authorization', "token #{gh_token}")
      .delete(JSON.stringify({assignees: [unassignee_requester]})) (err, res, body) ->
        if res.statusCode is not 200 or err
          if err is not undefined
            msg.send "Unassigning failed :( #{err})"
          else
            msg.send "Unassigning failed :( #{res.statusCode}"
        else
          msg.send "Unassigned, @#{unassignee_requester}!"
