class FeedSettings
  constructor: (content) ->
    @name = ''
    @description = ''
    @output = ''
    @input = ''
    @include = []
    @exclude = []

    @form = content.$ '#add-feed form'

    @form.$('#submit-add-feed').on 'click', @submit
    @form.$('#input-type-search').on 'input', @keywordSearch
    @form.$('#add-feed-include').on 'click', @addInclude
    @form.$('#add-feed-exclude').on 'click', @addExclude

    @form.$('[name=name]').on 'input', (e) =>
      @name = e.target.value
      @reeval()

    @form.$('[name=description]').on 'input', (e) =>
      @description = e.target.value
      @reeval()

    @form.$('[name=output-type]').on 'input', (e) =>
      @output = e.target.value
      @reeval()

  submit: (e) =>
    error heading: 'unimplemented'

  # check if everything is okay, then grab a preview from the server
  reeval: =>
    preview = $('#feed-preview .feed')
    preview.clear()

    if @include.length is 0 and @exclude.length is 0
      make
        tag: 'p'
        text: 'You need at least one thing to either include or exclude'
        base: preview

      return

    if @output is ''
      make
        tag: 'p'
        text: 'Need an output type'
        base: preview

      return

    ajax
      method: 'post'
      path: '/ajax/feed/preview'
      data: JSON.stringify {
        @input
        @output
        @include
        @exclude
        @name
        @description
      }
      async: true
      callback: (e) ->
        x = e.target
        switch x.status
          when 200
            preview.innerHTML = x.response
          else
            make
              tag: 'p'
              text: "There was a problem getting the feed preview. Try again later?"
              base: preview

            try
              resp = JSON.parse x.response
              console.log resp.msg
            catch err
              console.log err


  keywordSearch: (e) =>

  addInclude: (e) =>

  addExclude: (e) =>

window.UserSettings = class
  constructor: ->
    @tabs = $$ '.tab-stack a'
    @windowLoc = $ '.settings'

    switch @windowLoc.attr 'id'
      when 'feed-settings'
        @page = new FeedSettings @windowLoc
      when 'profile-settings'
        debugger
        # etc

