# utilities

$ = (sel, base) ->
  base = document if not base?
  base.querySelector sel

$$ = (sel, base) ->
  base = document if not base?
  base.querySelectorAll sel

HTMLElement::on = (evt, func, bubble) ->
  if evt.constructor.name is 'Array'
    this.addEventListener e, func, bubble for e in evt
  else
    # add a touchend event automatically for click events
    if evt is 'click'
      this.addEventListener 'touchend', func, bubble
    this.addEventListener evt, func, bubble
  
ajaxPost = (path, data, async, callbacks) ->
  x = new XMLHttpRequest()

  if callbacks?
    switch typeof(callbacks)
      when 'object'
        x.addEventListener(evt, callback, false) for evt, callback of callbacks

      when 'function'
        x.addEventListener 'load', callbacks, true

  x.open 'post', path, async

  if typeof data is 'object'
    fd = new FormData
    fd.append key, val for key, val of data
    x.send fd
  else
    x.send data

make = (tag, attrs, text) ->
  elem = document.createElement(tag)

  if attrs?
    for name, attr of attrs
      if attr?
        elem.setAttribute name, attr
      else
        elem.setAttribute name

  if text?
    elem.innerText = text

  return elem

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

  loginButton.setAttribute 'disabled'
  old = loginButton.innerHTML
  loginButton.innerText = 'Logging in...' # TODO: change to a spinner

  ajaxPost '/login',
    'user': user.value
    'pass': password.value
    'page': $('body').getAttribute('id'),
    true, (e) ->
      # get rid of errors that might be left over
      # TODO: inline errors instead of lazy alert()
      # form.removeChild error for error in $$ '.error', form

      x = e.srcElement
      switch x.status
        when 200
          $('#cp').innerHTML = x.response
        else
          resp = JSON.parse x.response
          alert resp.msg

      loginButton.innerHTML = old
      loginButton.removeAttribute 'disabled'

logout = (e) ->
  button = e.target
  button.setAttribute 'disabled'
  old = button.innerText
  button.innerText = 'Logging out...'

  ajaxPost '/logout', null, true, (e) ->
    x = e.srcElement
    console.log e
    switch x.status
      when 200
        $('#cp').innerHTML = x.response
        $('#login-button').addEventListener 'click', login, false
      else
        resp = JSON.parse x.response
        alert resp.msg

class Series
  constructor: () ->
    @tags = $ '#tags li a'
    tag.addEventListener 'click', showTagInfo, false for tag in @tags

    @tagShown = null
    @tagInfo = null

showTagInfo = (e) ->
  a = e.targetElement

  if THIS.tagShown? and THIS.tagShown is a.innerText
    return

  info = THIS.tagInfo
  info.style.display = 'none'

  if not info?
    ajaxPost '/ajax/tag-info', 'tagName': a.innerText, false, (e) ->
      resp = JSON.parse e.response
      if resp.err isnt null
        alert resp.msg
        return

      info = make 'div', 'id': 'tag-info'
      info.innerHTML = resp.msg

      $('#tag-upvote', info).addEventListener 'click', (e) ->
        # ajax post...
        false
      , false

      $('#tag-downvote', info).addEventListener 'click', (e) ->
        # ajax post...
        false
      , false

      THIS.tagInfo = info
      document.body.appendChild info

  if not info?
    alert 'Something went wrong getting tag info'
    return

  desc = $ '#tag-desc', info
  ajaxPost '/ajax/tag-desc', 'tagName': a.innerText, false, (e) ->
    resp = JSON.parse e.response
    if resp.err isnt null
      alert resp.msg
      return

    desc.innerText = resp.msg

  info.style.display = 'block'

  info.style.left = a.offsetWidth + a.offsetLeft + 8 + 'px'
  info.style.top = a.offsetHeight/2 + a.offsetTop - info.offsetHeight
  THIS.tagShown = a.innerText

  # if user clicks outside the popup, close it
  document.body.addEventListener 'click', (e) ->
    el = e.targetElement
    if el isnt info and el.parentElement isnt info
      hideTagInfo()
    true # keep going down the click events.
  , true

hideTagInfo = ->
  if not THIS.tagInfo?
    return

  tagInfo.style.display = 'none'
  THIS.tagShown = ''

pageObjects =
  'series': Series

THIS = null

main = ->
  pairs = [
    #['#search button', doSearch]
    ['#login-button', login]
    ['#logout-button', logout]
  ]
  for pair in pairs
    try
      $(pair[0]).addEventListener 'click', pair[1], false
    catch e
      console.log "Element: #{pair[0]}"
      console.log e.stack

  if (page = $('body').getAttribute 'id').length > 0
    THIS = new pageObjects[page]()

window.addEventListener 'load', main, true
window.addEventListener 'load', ->
  $('head').appendChild make 'script',
    async: true
    src: "http://#{document.domain}:8080/livereload.js"
