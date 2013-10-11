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

# send an ajax request
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

# global handlers

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

window.on 'DOMContentLoaded', main, true
window.on 'DOMContentLoaded', ->
  document.head.appendChild make
    tag: 'script'
    attrs:
      async: true
      src: "http://#{document.domain}:8080/livereload.js"
