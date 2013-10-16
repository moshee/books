# utilities

$ = (sel) ->
  document.body.querySelector sel

$$ = (sel) ->
  document.body.querySelectorAll sel

Element::$ = (sel) ->
  @querySelector sel

Element::$$ = (sel) ->
  @querySelectorAll sel

Element::on = XMLHttpRequest::on = Window::on = (events, func, capture) ->
  capture ?= false

  for evt in events.split(/\s+/)
    # add a touchend event automatically for click events
    if evt is 'click'
      @addEventListener 'touchend', func, capture
    @addEventListener evt, func, capture

# Beginnings of DOMContentLoaded support. Fill in with polyfills later as
# needed.
begin = (func) ->
  window.on 'DOMContentLoaded', func, false

HTMLElement::css = (obj) ->
  @style[key] = val for key, val of obj

Element::attr = (obj) ->
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

  if opts.callback?
    switch typeof opts.callback
      when 'object'
        x.on(evt, func, false) for evt, func of opts.callback

      when 'function'
        x.on 'load', opts.callback, false

  x.open opts.method, opts.path, opts.async

  if opts.headers?
    x.setRequestHeader header, val for header, val of opts.headers

  if opts.data?
    if opts.data.constructor.name is 'FormData'
      x.send opts.data
    else
      fd = new FormData
      fd.append key, val for key, val of opts.data
      x.send fd
  else
    x.send()

dashToCamel = (str) ->
  str.replace /(?:^|\-+)(.?)/, (m, w) -> w.toUpperCase()

# Create an arbitrary tree of HTML elements
# opts:
#   tag        The tag name (blank for text node).
#   base       The element's intended parent element. Blank for none.
#   text       innerText.
#   html       innerHTML.
#   callback   A function with the current element passed in, used to nest
#              however deep is needed, or to do whatever with the element.
make = (opts) ->
  if not opts.tag?
    elem = document.createTextNode opts.text
    if opts.base? then opts.base.appendChild elem
    return elem

  elem = document.createElement opts.tag

  if opts.base?     then opts.base.appendChild elem
  if opts.attrs?    then elem.attr opts.attrs
  if opts.text?     then elem.innerText = opts.text
  if opts.html?     then elem.innerHTML = opts.html
  if opts.data?     then elem.dataset[key] = val for key, val of opts.data
  if opts.callback? then opts.callback elem

  elem

# Fill in the error pane, creating if needed
# options: heading, body, buttons { class, text, callback }
error = (opts) ->
  shroud = $ '#shroud'
  if shroud?
    shroud.css display: 'block'
  else
    shroud = make
      tag: 'div'
      attrs:
        id: 'shroud'
        class: 'disabled'
      base: document.body

  pane = $ '#error-pane'
  if pane?
    pane.$('h1').innerHTML = opts.heading
    if opts.msg?
      pane.$('p').innerHTML = opts.msg
    else
      pane.$('p').innnerHTML = ''
    return

  pane = make
    tag: 'div'
    attrs:
      id: 'error-pane'
    base: document.body
    callback: (base) ->
      make
        tag: 'h1'
        html: opts.heading
        base: base

      if opts.msg?
        make
          tag: 'p'
          html: opts.msg
          base: base

      if opts.buttons?
        for button in buttons
          el = make
            tag: 'button'
            attrs:
              type: 'button'
              class: button.class
            text: button.text
            base: base

          el.on 'click', button.callback
      else
        el = make
          tag: 'button'
          attrs: type: 'button'
          text: 'Okay'
          base: base
        
        el.on 'click', (e) ->
          # TODO: animation
          pane.css display: 'none'
          shroud.css display: 'none'

# global handlers

login = (e) ->
  loginButton = e.target
  form = loginButton.parentElement

  user = form.$ 'input[name=user]'
  password = form.$ 'input[name=pass]',
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
      'page': document.body.attr 'id'
    async: true
    callback: (e) ->
      # get rid of errors that might be left over
      # TODO: inline errors instead of lazy alert()
      # form.removeChild error for error in $$ '.error', form

      x = e.srcElement
      switch x.status
        when 200
          $('#cp').innerHTML = x.response
          window.dispatchEvent new CustomEvent 'login', username: user.value
          $('#logout-button').on 'click', logout
        else
          try
            resp = JSON.parse x.response
            error
              heading: 'Login failure'
              msg: resp.msg
          catch e
            console.log e

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
      x = e.target

      switch x.status
        when 200
          $('#cp').innerHTML = x.response
          $('#login-button').on 'click', login, false
          window.dispatchEvent new Event 'logout'
        else
          resp = JSON.parse x.response
          alert resp.msg
          button.attr disabled: no
          button.innerText = old

THIS = null

main = ->
  pairs =
    '#login-button': login
    '#logout-button': logout

  for name, func of pairs
    el = $ name
    if el?
      el.on 'click', func, false

  if (page = document.body.attr 'id')?
    THIS = new window[dashToCamel page]()

begin main

# separate event handler because we want this to happen even if main() fails
begin ->
  document.head.appendChild make
    tag: 'script'
    attrs:
      async: true
      src: "http://#{document.domain}:8080/livereload.js"
