IssuesOnGithubView = require './issues-on-github-view'
{CompositeDisposable} = require 'atom'

module.exports = IssuesOnGithub =
  issuesOnGithubView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @view = new IssuesOnGithubView();
    #@issuesOnGithubView = new IssuesOnGithubView(state.issuesOnGithubViewState)
    #@modalPanel = atom.workspace.addModalPanel(item: @issuesOnGithubView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    #@subscriptions = new CompositeDisposable

    # Register command that toggles this view
    #@subscriptions.add atom.commands.add 'atom-workspace', 'issues-on-github:toggle': => @toggle()

  deactivate: ->

  serialize: ->
