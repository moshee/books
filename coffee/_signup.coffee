window.Signup = class
  @passwordMessages = [
    "You're gonna need a password."           # ≤0.0
    "Come on, that's not a password."         # ≤0.1
    "You need a better password than that."   # ≤0.2
    "You can do better than that, can't you?" # ≤0.3
    "I guess it could be worse..."            # ≤0.4
    "Not bad. Not particularly good, either." # ≤0.5
    "Getting there. Room for improvement."    # ≤0.6
    "That's more like it."                    # ≤0.7
    "That's a pretty good one!"               # ≤0.8
    "You know how to pick your passwords."    # ≤0.9
    "You are a password master! Now finish the rest of the form."
  ]

  constructor: ->
    @form = $ '#signup-form'
    @usernameValid = no
    @emailValid = no
    @passwordValid = no
    @submitButton = @form.$ '#submit'
    @updateButton()
    @usernameValidateTimeout = null

    window.on 'login', (e) ->
      window.location = '/'
    
    @form.$('#username').on 'input', (input) =>
      # make it so the button is disabled while they're typing during the time
      # it's waiting to make the ajax request
      @usernameValid = no
      @updateButton()

      if @usernameValidateTimeout?
        window.clearTimeout @usernameValidateTimeout

      if input.target.value.length is 0
        @usernameValid = no
        @msg '#username', "I'm sorry, did you type in a username? I don't see it."
        input.target.attr class: 'bad'

        @updateButton()
        return

      @usernameValidateTimeout = window.setTimeout =>
        @validateUsername input.target.value, (e) =>
          window.clearTimeout @usernameValidateTimeout
          @usernameValidateTimeout = null

          if e.target.status isnt 200
            @usernameValid = no
            @msg '#username', 'Something wrong happened while checking if that username is okay. Try signing up again later.'
            try
              resp = JSON.parse e.target.response
              console.log resp
            catch e
              # whatever
            return

          resp = JSON.parse e.target.response

          if resp.ok
            @usernameValid = yes
            @msg '#username', "<strong>#{input.target.value}</strong>, is it? Nice to meet you."
            input.target.attr class: 'good'
          else
            @usernameValid = no
            @msg '#username', resp.msg.replace('<NAME>', "<strong>#{input.target.value}</strong>")
            input.target.attr class: 'bad'

          @updateButton()
      , 1000

    @form.$('#email').on 'input', (e) =>
      val = e.target.value
      if val.length is 0
        @emailValid = no
        e.target.attr class: 'bad'
        @msg '#email', 'I need your e-mail address.'
      else if not /^\S+@\S+\.\S+/.test val
        @emailValid = no
        e.target.attr class: 'bad'
        @msg '#email', "That doesn't look like an e-mail address."
      else
        @emailValid = yes
        e.target.attr class: 'good'
        @msg '#email', "You'll be sent an email once you sign up to make sure you're there."

      @updateButton()

    pass = @form.$ '#password'
    repeat = @form.$ '#repeat-password'

    passCallback = (e) =>
      if pass.value.length is 0
        pass.attr class: 'bad'
        return

      pass.attr class: 'good'

      if pass.value is repeat.value
        @passwordValid = yes
        repeat.attr class: 'good'
        @msg '#repeat-password', 'Passwords match. Good job.'
      else
        @passwordValid = no
        repeat.attr class: 'bad'
        @msg '#repeat-password', "Passwords don't match."

      @updateButton()

    pass.on 'input', (e) =>
      @showPassStrength pass.value
      passCallback e
    repeat.on 'input', passCallback
    
  formValue: (sel) =>
    @form.$(sel).value
    
  setFormValue: (sel, value) =>
    @form.$(sel).value = value
    
  # Attach a message to a form element
  # str may be an element
  msg: (target, str, attrs) =>
    p = @form.$ "p.field-feedback[data-for=\"#{target}\"]"

    if p?
      if typeof str is 'string'
        p.innerHTML = str
      else
        p.removeChild p.firstChild while p.firstChild?
        p.appendChild str
      p.attr attrs

    else
      if typeof str is 'string'
        p = make
          tag: 'p'
          html: str
          attrs: attrs
          data: for: target
          callback: (base) ->
            base.classList.add 'field-feedback'

      else
        p = make
          tag: 'p'
          attrs: attrs
          data: for: target
          callback: (base) ->
            base.classList.add 'field-feedback'
            base.appendChild str

      input = @form.$ target
      input.parentElement.insertBefore p, input.nextSibling

  submit: =>
    if not @formValid()
      return
    
    ajax
      method: 'post'
      path: '/signup'
      data: new FormData @form
      async: on
      callback: (e) =>
        x = e.target
        switch x.status
          when 200
            loc = x.getResponseHeader 'Location'
            if loc.length isnt 0
              # a reroute
              window.location = loc
              return

            alert 'success'
            window.location = '/'
          else
            resp = JSON.parse e.response
            error resp.msg

  formValid: =>
    valid = @usernameValid and @passwordValid and @emailValid
    console.log valid
    valid

  updateButton: =>
    if @formValid()
      @submitButton.attr disabled: null
    else
      @submitButton.attr disabled: yes
      
  # Check with the server to see if the username is free and valid.
  validateUsername: (username, callback) ->
    ajax
      method: 'post'
      path: '/ajax/validate/username'
      data: {username}
      async: on
      callback: callback
    
  # Overly complicated and mathy way to calculate  password strength as a
  # combination of length and character variety.
  scorePassword: (password) ->
    x = password.length
    return 0 if x is 0

    # The more types of characters, the better.
    ranges = [/[0-9]/, /[a-z]/, /[A-Z]/, /\W/]
      .map((r) -> r.test password)
      .reduce ((a, b) -> if b then a + 1 else a), 0

    # the less ranges, the harder it is for the function to reach 1.0
    # If this number is lower, it'll get closer to 1.0 faster
    # (but a long enough password will eventually do so)
    div = [100, 9, 8, 7, 6][ranges]

    # more character variety is better. More character variety -> lower div.
    charMap = {}
    charMap[ch] = true for ch in password
    chars = 0
    chars = chars++ for ch of charMap
    div *= 1 + 2 / (3*chars + 3) # Starts at a ~1.7 multiplier, tapers to 1.0

    # Start really low with a short password. Diminishing returns at 16-20
    # characters long.
    1 - (x+20) * Math.pow(Math.E, -x/div - 3)

  showPassStrength: (password) =>
    score = @scorePassword password
    index = Math.ceil score*10
    c = index * 5

    span = make
      tag: 'span'
      text: Signup.passwordMessages[index]

    # from grey to green
    span.css color: "rgb(#{128-c}, #{128+c}, #{128-c})"

    @msg '#password', span
