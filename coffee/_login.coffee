window.Login = class
  constructor: ->
    @form = $ 'form#login'

    @submit = @form.$ 'button#submit'

    @submit.on 'click', (e) =>
      doLogin e, (e) =>
        x = e.target
        if x.status is 200
          window.dispatchEvent new CustomEvent 'login'
          loc = @form.dataset.location
          if loc is ''
            window.location = '/'
          else
            window.location = loc
