(function() {
	// utils
	//
	function $(sel, base) {
		if (base == null) base = document;
		return base.querySelector(sel);
	}

	function $$(sel, base) {
		if (base == null) base = document;
		return base.querySelectorAll(sel);
	}

	function ajax_post(path, data, async, callbacks) {
		var x = new XMLHttpRequest();
		switch (typeof callbacks) {
		case 'object':
			for (var evt in callbacks) {
				x.addEventListener(evt, callbacks[evt]);
			}
			break;

		case 'function':
			x.addEventListener('load', callbacks, true);
			break;
		}

		x.open('post', path, async);

		if (typeof data === 'object') {
			var fd = new FormData();
			for (var key in data) {
				fd.append(key, data[key]);
			}

			x.send(fd);
		} else {
			x.send(data);
		}
	}

	function make(tag, attrs, text) {
		var elem = document.createElement(tag);
		if (attrs) {
			for (var attr in attrs) {
				if (attrs[attr] == null) {
					elem.setAttribute(attr);
				} else {
					elem.setAttribute(attr, attrs[attr]);
				}
			}
		}
		if (text) {
			elem.innerText = text;
		}
		return elem;
	}

	// search

	// pjax that shit up
	// replace the section#main content and transition that shit in
	// with some slick animations
	function doSearch(e) {
		e.target.setAttribute('disabled');
		var old = e.target.innerHTML;
		e.target.innerHTML = 'Please wait...';

		var s = {};
		var lis = $$('li', searchFilter);
		for (var i = 0, li; li = lis[i]; i++) {
			var input = $('input', li).value;
			if (input.length == 0) {
				continue;
			}
			var select = $('select', li).value;

			if (typeof s[select] === 'undefined') {
				s[select] = [input];
			} else {
				s[select].push(input);
			}
		}

		ajax_post('/search', s, true, function(x) {
			e.target.removeAttribute('disabled');
			e.target.innerHTML = old;
		});
	}

	var searchFilter, searchFilterItem;

	function addSearchFilterItem() {
		if (typeof searchFilterItem === 'undefined') return;

		var node = searchFilterItem.cloneNode(true);
		$('input', node).value = '';
		$('select', node).selectedIndex = 0;

		searchFilter.appendChild(node);
		$('button.remove-filter', node)
			.addEventListener('click', delSearchFilterItem, false);
	}

	function delSearchFilterItem(e) {
		var li = e.target.parentNode;
		li.parentNode.removeChild(li);
	}

	// login
	
	function login(e) {
		var loginButton = e.target;

		var section = $('section.auth');
		var form = $('form', section);

		var user = $('#user', form);
		var password = $('#pass', form);
		var bad = false;

		if (user.value.length == 0) {
			user.classList.add('invalid');
			bad = true;
		} else {
			user.classList.remove('invalid');
		}

		if (password.value.length == 0) {
			password.classList.add('invalid');
			bad = true;
		} else {
			password.classList.remove('invalid');
		}

		if (bad) {
			return;
		}

		user.classList.remove('invalid');
		password.classList.remove('invalid');	
		form.classList.remove('invalid');

		loginButton.setAttribute('disabled');
		var old = loginButton.innerHTML;
		loginButton.innerText = 'Logging in...';
		var registerButton = $('#register-button', form);
		registerButton.setAttribute('disabled');

		ajax_post('/login', {
			'user': user.value,
			'pass': password.value
		}, true, function(e) {
			// get rid of any errors that might be there from the last attempt
			var errors = $$('.error', form);
			for (var i = 0, error; error = errors[i]; i++) {
				form.removeChild(error);
			}

			var x = e.srcElement;
			switch (x.status) {
			case 200:
				// okay, replace contents
				section.outerHTML = x.response;
				$('#logout-button')
					.addEventListener('click', logout, false);
				break;
			case 400:
				// bad password probably
				var resp = JSON.parse(x.response);
				var p = make('p', {'class': 'error'}, 'Error: ' + resp.msg);

				form.insertBefore(p, user);
				break;
			case 500:
				// something wrong with the server
				var resp = JSON.parse(x.response);
				var p = make('p', {'class': 'error'},
							 'Server error: ' + resp.msg);
				form.insertBefore(p, user);

				var m = make('p', {'class': 'error'},
							 'This should not happen. ' +
							 'You should probably report this error.');
				form.insertBefore(m, p.nextSibling);
				break;
			}

			loginButton.innerHTML = old;
			loginButton.removeAttribute('disabled');
			registerButton.removeAttribute('disabled');
		});
	}

	function logout(e) {
		var button = e.target;
		button.setAttribute('disabled');
		var old = button.innerText;
		button.innerText = 'Logging out...';
		var form = $('section.auth');

		ajax_post('/logout', null, true, function(e) {
			var x = e.srcElement;
			console.log(e);
			switch (x.status) {
			case 200:
				// okay, replace contents
				form.outerHTML = x.response;
				$('#login-button')
					.addEventListener('click', login, false);
				break;
			case 400:
				// bad password probably
				var resp = JSON.parse(x.response);
				var p = make('p', {'class': 'error'}, 'Error: ' + resp.msg);
				form.appendChild(p);

				break;
			case 500:
				// something wrong with the server
				var resp = JSON.parse(x.response);
				var p = make('p', {'class': 'error'},
							 'Server error: ' + resp.msg);
				var m = make('p', {'class': 'error'},
							 'This should not happen. ' +
							 'You should probably report this error.');

				form.appendChild(p);
				form.appendChild(m);
				break;
			}

			button.removeAttribute('disabled');
			button.innerText = old;
		});
	}

	function main() {
		searchFilter = $('#search ul');
		searchFilterItem = $('li', searchFilter); 

		$('#add-filter').addEventListener('click', addSearchFilterItem, false);
		$('button.remove-filter', searchFilterItem)
			.addEventListener('click', delSearchFilterItem, false);
		$('#search-button').addEventListener('click', doSearch, false);

		var loginButton = $('#login-button');
		if (loginButton != null) {
			loginButton.addEventListener('click', login, false);
		}

		var logoutButton = $('#logout-button');
		if (logoutButton != null) {
			logoutButton.addEventListener('click', logout, false);
		}

	}

	window.addEventListener('load', main, true);
	window.addEventListener('load', function() {
		var lr = document.createElement('script');
		lr.async = true;
		lr.src = 'http://' + document.domain + ':8080/livereload.js';
		$('head').appendChild(lr);
	}, true);
})();
