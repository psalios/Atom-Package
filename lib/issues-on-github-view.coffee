path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'

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
            console.log page
            console.log atom.workspace.getActiveTextEditor().getSelectedText()
            @previouslyFocusedElement = $(document.activeElement)
            @close()

        close: ->
          return unless @panel.isVisible()
          @panel.hide()
          @previouslyFocusedElement?.focus()

        attach: ->
            @panel ?= atom.workspace.addModalPanel(item: this)
            @panel.show()
            @message.text("Please enter the title of the issue")
            @selectEditor.focus()
