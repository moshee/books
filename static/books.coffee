# utilities

$ = (sel, base) ->
  base = document if not base?
  base.querySelector sel

$$ = (sel, base) ->
  base = document if not base?
  base.querySelectorAll sel

ajaxPost = (path, data, async, callbacks) ->
  x = new XMLHttpRequest()

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

window.addEventListener 'load', main, true
window.addEventListener 'load', ->
  $('head').appendChild make 'script',
    async: true
    src: "http://#{document.domain}:8080/livereload.js"
