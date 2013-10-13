window.Signup = class
  constructor: ->
    @form = $ '#signup-form'
    @usernameValid = no
    
    @form.$('#username').on 'input', (e) =>
      msg = @form.$ 'p.field-feedback[data-for=username]'
      @validateUsername e.target.value, (e) =>
        resp = JSON.parse e.target.response
        @usernameValid = resp.ok

        if not @usernameValid
          msg.attr class: bad
          msg.innerText = resp.msg
        else
          msg.attr class: good
          msg.innerText = '✓'
    
  formValue: (sel) =>
    @form.$(sel).value
    
  setFormValue: (sel, value) =>
    @form.$(sel).value = value
    
  submit: =>
    if not @formValid()
      return
    
    ajax
      method: 'post'
      path: '/ajax/signup'
      data: new FormData @form
      async: on
      callback: (e) =>
        x = e.target
        if x.status is 200
          alert 'success'
          window.location = '/'
        else
          resp = JSON.parse e.response
          error resp.msg
      
  formValid: =>
    @usernameValid
    
  # Check with the server to see if the username is free and valid.
  validateUsername: (username, callback) ->
    ajax
      method: 'post'
      path: '/ajax/validate/username'
      data: {username}
      async: on
      callback: callback
    
  # Calculate password strength as a combination of length and character range
  # variety.
  scorePassword: (password) ->
    x = password.length
    # Start really low with a short password. Diminishing returns at 16-20
    # characters long.
    score = 1 - (x+20) * Math.pow(Math.E, -x/5 - 3)
  
    # The more types of characters, the better.
    ranges = [/[0-9]/, /[a-z]/, /[A-Z]/, /[\W_]/]
      .map((r) -> r.test password)
      .reduce ((a, b) -> if b then a + 1 else a), 0
    
    # side effect: zero-length password will give a 0 strength because it won't
    # match any character ranges.
    score *= [0, 0.5, 0.7, 0.8, 0.95][ranges]
