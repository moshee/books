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

	function ajax_post(path, data, async, callback) {
		var x = new XMLHttpRequest();
		if (typeof callback !== 'undefined') {
			x.addEventListener('load', callback, true);
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
		e.target.setAttribute('disabled');
		e.target.innerText = 'Logging in...';

		var form = e.target.parentElement;
		
	}

	function main() {
		searchFilter = $('#search ul');
		searchFilterItem = $('li', searchFilter); 

		$('#add-filter').addEventListener('click', addSearchFilterItem, false);
		$('button.remove-filter', searchFilterItem)
			.addEventListener('click', delSearchFilterItem, false);
		$('#search-button').addEventListener('click', doSearch, false);

		$('#login-button').addEventListener('click', login, false);

		var lr = document.createElement('script');
		lr.async = true;
		lr.src = 'http://' + document.domain + ':8080/livereload.js';
		$('head').appendChild(lr);
	}

	window.addEventListener('load', main, true);
})();
