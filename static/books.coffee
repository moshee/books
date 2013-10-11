# utilities

$ = (sel, base) ->
  base = document if not base?
  base.querySelector sel

$$ = (sel, base) ->
  base = document if not base?
  base.querySelectorAll sel

HTMLElement::on = XMLHttpRequest::on = Window::on = (evt, func, capture) ->
  capture ?= false

  if evt.constructor.name is 'Array'
    this.addEventListener e, func, capture for e in evt
  else
    # add a touchend event automatically for click events
    if evt is 'click'
      this.addEventListener 'touchend', func, capture
    this.addEventListener evt, func, capture

HTMLElement::css = (obj) ->
  @style[key] = val for key, val of obj

HTMLElement::attr = (obj) ->
  switch typeof obj
    when 'string'
      @getAttribute obj
    when 'object'
      for key, val of obj
        if val is null
          @removeAttribute key
        else
          @setAttribute key, val

ajax = (opts) ->
  x = new XMLHttpRequest()
  opts.method ||= 'post'
  unless opts.async?
    opts.async = false

  if opts.attrs?
    x[name] = attr for name, attr of opts.attrs

  if opts.headers?
    x.setRequestHeader header, val for header, val of opts.headers

  if opts.callback?
    switch typeof opts.callback
      when 'object'
        x.on(evt, func, false) for evt, func of opts.callback

      when 'function'
        x.on 'load', opts.callback, false

  x.open opts.method, opts.path, opts.async

  if typeof opts.data is 'object'
    fd = new FormData
    fd.append key, val for key, val of opts.data
    x.send fd
  else
    x.send opts.data

make = (opts) ->
  if not opts.tag?
    elem = document.createTextNode opts.text
    if opts.base? then opts.base.appendChild elem
    return elem

  elem = document.createElement opts.tag

  if opts.base?     then opts.base.appendChild elem
  if opts.attrs?    then elem.attr opts.attrs
  if opts.text?     then elem.attr innerText: opts.text
  if opts.children? then elem.appendChild opts.children elem

  elem

# handlers

login = (e) ->
  loginButton = e.target
  form = loginButton.parentElement

  user = $ 'input[name=user]', form
  password = $ 'input[name=pass]', form
  bad = false

  if user.value.length is 0
    user.classList.add 'invalid'
    bad = true
  else
    user.classList.remove 'invalid'

  if password.value.length is 0
    password.classList.add 'invalid'
    bad = true
  else
    password.classList.remove 'invalid'

  return if bad

  user.classList.remove 'invalid'
  password.classList.remove 'invalid'

  loginButton.attr disabled: yes
  old = loginButton.innerHTML
  loginButton.innerText = 'Logging in...' # TODO: change to a spinner

  ajax
    method: 'post'
    path: '/login'
    data:
      'user': user.value
      'pass': password.value
      'page': $('body').attr 'id'
    async: true
    callback: (e) ->
      # get rid of errors that might be left over
      # TODO: inline errors instead of lazy alert()
      # form.removeChild error for error in $$ '.error', form

      x = e.srcElement
      switch x.status
        when 200
          $('#cp').innerHTML = x.response
        else
          throw toString: -> x.response

      loginButton.innerHTML = old
      loginButton.attr disabled: null

logout = (e) ->
  button = e.target
  button.attr disabled: yes
  old = button.innerText
  button.innerText = 'Logging out...'

  ajax
    method: 'post'
    path: '/logout'
    async: yes
    callback: (e) ->
      x = e.srcElement
      switch x.status
        when 200
          $('#cp').innerHTML = x.response
          $('#login-button').on 'click', login, false
        else
          resp = JSON.parse x.response
          alert resp.msg
          false


class Series
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
            a = $ 'a', li
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

        if (upvote = $ 'a#tag-upvote', @tagInfo)?
          upvote.on 'click', @voteTag(a, 'up'), false

        if (downvote = $ 'a#tag-downvote', @tagInfo)?
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
    lis = $$ 'li', ul

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

pageObjects =
  'series': Series

THIS = null

main = ->
  pairs =
    '#login-button': login
    '#logout-button': logout

  for name, func of pairs
    el = $ name
    if el?
      el.on 'click', func, false

  if (page = document.body.attr 'id').length > 0
    THIS = new pageObjects[page]()

window.on 'load', main, true
window.on 'load', ->
  $('head').appendChild make
    tag: 'script'
    attrs:
      async: true
      src: "http://#{document.domain}:8080/livereload.js"
