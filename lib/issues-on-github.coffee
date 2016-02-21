IssuesOnGithubView = require './issues-on-github-view'
{CompositeDisposable} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
request = require 'request'
protocol = require 'https'

GH_REGEX = /^(https:\/\/|git@)github\.com(\/|:)([-\w]+)\/([-\w]+)(\.git)?$/

issuesUrl = (info) ->
  "https://api.github.com/repos/#{info.user}/#{info.repo}/issues?state=all"

getOriginURL = -> atom.project.getRepositories()[0]?.getOriginURL() or null

isGitHubRepo = ->
  return false unless getOriginURL()
  m = getOriginURL().match GH_REGEX
  if m
    {
      user: m[3]
      repo: m[4]
    }
  else
    false

repo = (info) ->
  info.repo

user = (info) ->
  info.user

module.exports = IssuesOnGithub =
  issuesOnGithubView: null
  modalPanel: null
  subscriptions: null

  config:
    userToken:
      title: 'OAuth token'
      description: 'Enter an OAuth token to have Gists posted to your GitHub account. This token must include the gist scope.'
      type: 'string'
      default: ''

  activate: (state) ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'issues-on-github:listen': =>
        console.log 'Listening'
      'issues-on-github:toggle': =>
        @view = new IssuesOnGithubView()

    setInterval (->
      console.log 'Checking'
      IssuesOnGithub.receive (err,issues) =>
        if err
          console.error err
        else
          for key of issues
            `key = key`
            username =  user(isGitHubRepo())
            repository = repo(isGitHubRepo())
            check = JSON.stringify(issues[key].user.login)
            console.log username
            console.log check
            if( username != check.substring(1,check.length-1) )
              if( repository.indexOf(check.substring(1,check.length-1) ) == -1 )
                atom.notifications.addInfo( "Issue from user " + JSON.stringify(issues[key].user.login) + " at " + JSON.stringify(issues[key].html_url) )
      ), 5000

  getSecretTokenPath: ->
    path.join(atom.getConfigDirPath(), "issues-on-github.token")

  getToken: ->
    if not @token?
      config = atom.config.get("issues-on-github.userToken")
      @token = if config? and config.toString().length > 0
                 config
               else if fs.existsSync(@getSecretTokenPath())
                 fs.readFileSync(@getSecretTokenPath())
    @token

  receive: (callback) ->
    if( issuesUrl(isGitHubRepo) )
      now = new Date((new Date).getTime() - 5*1000);
      str = now.toISOString();
      options =
        uri: "https://api.github.com/repos/#{user(isGitHubRepo())}/#{repo(isGitHubRepo())}/issues?since=#{str}",
        method: 'GET',
        headers:
            'Authorization': "token #{@getToken()}",
            'User-Agent': "Atom"
      request options, (err, resp, body) ->
        if err
          callback err
        else
          try
            issues = JSON.parse body
            callback null, issues
          catch err
            console.log 'ERR', body
            callback err

  deactivate: ->

  serialize: ->
