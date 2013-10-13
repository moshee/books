class Signup
	constructor: ->
		@form = $ '#signup'
		@usernameValid = no
		
		$('#username', @form).on 'input', (e) =>
			@validateUsername e.target.value, (e) =>
				resp = JSON.parse e.target.response
				if not @usernameValid = resp.ok
					msg.innerText = resp.msg
				else
					msg.innerText = ''
		
	formValue: (sel) =>
		$(sel, @form).value
		
	setFormValue: (sel, value) =>
		$(sel, @form).value = value
		
	submit: =>
		if not @formValid()
			return
		
		ajax
			method: 'post'
			
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
		score = 1 - (x+20) * Math.pow(Math.E, -x/5 - 3)
	
		ranges = [/[0-9]/, /[a-z]/, /[A-Z]/, /[\W_]/]
			.map((r) -> r.test password)
			.reduce ((a, b) -> if b then a + 1 else a), 0
		
		score *= [0, 0.5, 0.7, 0.8, 0.95][ranges]