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

		var form = loginButton.parentElement;

		var user = $('input[name=user]', form);
		var password = $('input[name=pass]', form);
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

		loginButton.setAttribute('disabled');
		var old = loginButton.innerHTML;
		loginButton.innerText = 'Logging in...';

		ajax_post('/login', {
			'user': user.value,
			'pass': password.value,
			'page': $('body').getAttribute('id')
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
				$('#cp').innerHTML = x.response;
				break;

			case 400:
				// bad password probably
				var resp = JSON.parse(x.response);
				alert(resp.msg);
				break;

			case 500:
				// something wrong with the server
				var resp = JSON.parse(x.response);
				alert(resp.msg);
				break;
			}

			loginButton.innerHTML = old;
			loginButton.removeAttribute('disabled');
		});
	}

	function logout(e) {
		var button = e.target;
		button.setAttribute('disabled');
		var old = button.innerText;
		button.innerText = 'Logging out...';

		ajax_post('/logout', null, true, function(e) {
			var x = e.srcElement;
			console.log(e);
			switch (x.status) {
			case 200:
				// okay, replace contents
				$('#cp').innerHTML = x.response;
				$('#login-button')
					.addEventListener('click', login, false);
				break;

			case 400:
				// bad password probably
				var resp = JSON.parse(x.response);
				alert(resp.msg);
				break;

			case 500:
				// something wrong with the server
				var resp = JSON.parse(x.response);
				alert(resp.msg);
				break;
			}

			button.removeAttribute('disabled');
			button.innerText = old;
		});
	}

	function register() {
	}

	function main() {
		[
			['#search button', doSearch],
			['#login-button', login],
			['#logout-button', logout]
		].forEach(function(pair) {
			try {
				$(pair[0]).addEventListener('click', pair[1], false);
			} catch (e) {
				console.log("Element: " + pair[0]);
				console.log(e.stack);
				return;
			}
		});
	}

	window.addEventListener('load', main, true);
	window.addEventListener('load', function() {
		var lr = document.createElement('script');
		lr.async = true;
		lr.src = 'http://' + document.domain + ':8080/livereload.js';
		$('head').appendChild(lr);
	}, true);
})();
