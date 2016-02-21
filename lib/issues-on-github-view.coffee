path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'
request = require 'request'
protocol = require 'https'

GH_REGEX = /^(https:\/\/|git@)github\.com(\/|:)([-\w]+)\/([-\w]+)(\.git)?$/

repo = (info) ->
  info.repo

user = (info) ->
  info.user

getOriginURL = -> atom.project.getRepositories()[0]?.getOriginURL() or null

isGitHubRepo = ->
  return false unless getOriginURL
  m = getOriginURL().match GH_REGEX
  if m
    {
      user: m[3]
      repo: m[4]
    }
  else
    false

module.exports =
    class IssuesOnGithubView extends View
        previouslyFocusedElement: null
        detaching: false
        @content: ->
            @div class: 'issues-on-github', =>
                @div class: 'message', outlet: 'message'
                @subview 'selectEditor', new TextEditorView(mini: true)

        initialize: ->
            @commandSubscription = atom.commands.add 'atom-workspace',
              'issues-on-github:toggle': => @attach()

            @selectEditor.on 'blur', => @close()
            atom.commands.add @element,
              'core:confirm': => @confirm()
              'core:cancel': => @close()

        destroy: ->
          @panel?.destroy()

        confirm: ->
            page = @selectEditor.getText()
            @selectEditor.setText("");
            #console.log page
            #console.log atom.workspace.getActiveTextEditor().getSelectedText()
            if isGitHubRepo()
              console.log 'Correct'
              @post (response) =>
                console.log response
            else
              console.log 'Error'
            @previouslyFocusedElement = $(document.activeElement)
            @close()

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

        post: (callback) ->
          options =
            host: 'api.github.com',
            port: 443,
            path: "/repos/#{user(isGitHubRepo())}/#{repo(isGitHubRepo())}/issues",
            method: 'POST',
            headers:
                'Authorization': "token #{@getToken()}",
                'User-Agent': "Atom"

          params =
            'title': "Found a bug",
            'body': "I'm having a problem with this."

          request = protocol.request options, (res) ->
            res.setEncoding "utf8"
            body = ''
            res.on "data", (chunk) ->
              body += chunk
            res.on "end", ->
              response = JSON.parse(body)
              callback(response)

          request.write(JSON.stringify(params))
          request.end()
          console.log options.path

        close: ->
          return unless @panel.isVisible()
          @panel.hide()
          @previouslyFocusedElement?.focus()

        attach: ->
            @panel ?= atom.workspace.addModalPanel(item: this)
            @panel.show()
            @message.text("Please enter the title of the issue")
            @selectEditor.focus()
