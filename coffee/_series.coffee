window.Series = class
  constructor: ->
    @tags = $$ '.tags li a'
    tag.on 'click', @showTagInfo, false for tag in @tags

    @editLink = $ '#edit-page'

    @tagShown = null
    @tagInfo = null

  # Display the tag info popup, getting the tag's description from the server
  # TODO: cache descriptions
  showTagInfo: (e) =>
    a = e.target
    e.preventDefault()

    # clicking on the link will have toggle behavior
    if @tagShown? and @tagShown is a.innerText
      @hideTagInfo()
      return

    @populateTagInfo a, =>
      @tagInfo.css display: 'block'
      @positionTagInfo a.parentElement
      @tagShown = a.innerText
      document.body.on 'click', @hideTagInfo, false

  # hide the tag info popup
  hideTagInfo: (e) =>
    if not @tagInfo? or @tagShown is ''
      document.body.removeEventListener 'click', @hideTagInfo, false
      return

    if not e?
      @tagInfo.css display: 'none'
      @tagShown = ''
      return # not an event, don't care about return

    # we want the view tag page link to still work as expected
    if e.target.attr('id') is 'tag-link'
      return
    e.preventDefault()

    # only hide if clicked outside of popup
    unless @tagInfo.contains e.target
      @tagInfo.style.display = 'none'
      @tagShown = ''
      document.body.removeEventListener 'click', @hideTagInfo, false

    true # keep going down the click events.

  # send the user's tag vote attempt to the server and replace data on page if
  # it was successful
  voteTag: (a, action) ->
    # click event handler
    (e) =>
      # prevent trying to respond to hyper excessive clicking.
      # the listeners will be added back in the call to @populateTagInfo.
      a.removeEventListener 'click', @voteTag
      a.removeEventListener 'touchend', @voteTag

      e.preventDefault()
      ajax
        method: 'post'
        path: '/ajax/tag/vote'
        data:
          'tag':    a.innerText
          'action': action
          'series': document.body.dataset.id
        async: true
        callback: (e) =>
          x = e.target
          if x.status is 200
            li = a.parentElement
            li.innerHTML = x.response # update with data from server

            # attach the events etc to the NEW link. The contents of li (a)
            # changed up there ↑↑
            a = li.$ 'a'
            a.on 'click', @showTagInfo

            @populateTagInfo a, =>
              @sortTag li, (li) ->
                parseInt li.innerText.slice li.innerText.search /(\+|\-)?\d+\)$/
              @tagInfo.css display: 'block'
              @positionTagInfo li
          else
            resp = JSON.parse x.response
            alert resp.msg

  # request the tag info popup contents from the server
  populateTagInfo: (a, callback) =>
    ajax
      method: 'post'
      path: '/ajax/tag/info'
      data:
        'tag':    a.innerText
        'series': document.body.dataset.id
      async: true
      callback: (e) =>
        x = e.target

        if x.status isnt 200
          resp = JSON.parse x.response
          alert resp.msg
          return false

        if @tagInfo?
          @tagInfo.css display: 'none'
        else
          @tagInfo = make
            tag: 'div'
            attrs:
              id: 'tag-info'
          document.body.appendChild @tagInfo

        @tagInfo.innerHTML = x.response

        if (upvote = @tagInfo.$ 'a#tag-upvote')?
          upvote.on 'click', @voteTag(a, 'up'), false

        if (downvote = @tagInfo.$ 'a#tag-downvote')?
          downvote.on 'click', @voteTag(a, 'down'), false

        callback() if callback?


  # position the tag info popup above the li
  positionTagInfo: (li) =>
    topEdge = li.offsetTop - window.scrollY

    @tagInfo.css
      left:    li.offsetLeft + 'px'
      top:     if topEdge < @tagInfo.offsetHeight
        li.offsetTop + li.offsetHeight + 8 + 'px'
      else
        li.offsetTop - @tagInfo.offsetHeight - 8 + 'px'

  # sort tag list elements in descending order using value returned by sortBy
  sortTag: (li, sortBy) ->
    ul = li.parentElement
    lis = ul.$$ 'li'

    thisVal = sortBy li

    prev = li.previousElementSibling
    next = li.nextElementSibling
    if (not prev? or sortBy(prev) >= thisVal) and (not next? or sortBy(next) <= thisVal)
      # already sorted
      return

    for other in lis
      if sortBy(other) < thisVal
        ul.insertBefore li, other
        return

    # stick it at the end if it's the lowest
    ul.appendChild li
