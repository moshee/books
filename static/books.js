(function() {
	function $(sel, base) {
		if (base == null) base = document;
		return base.querySelector(sel);
	}

	function $$(sel, base) {
		if (base == null) base = document;
		return base.querySelectorAll(sel);
	}

	// pjax that shit up
	// replace the section#main content and transition that shit in
	// with some slick animations
	function doSearch() {
		s = [];
		var lis = $$('li', searchFilter);
		for (var i = 0, li; li = lis[i]; i++) {
			var input = $('input', li).value;
			if (input.length == 0) {
				continue;
			}
			var select = $('select', li).value;
			var o = {};
			o[select] = input;
			s.push(o);
		}
		console.log(s);
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

	function main() {
		searchFilter = $('#search ul');
		searchFilterItem = $('li', searchFilter); 

		$('#add-filter').addEventListener('click', addSearchFilterItem, false);
		$('button.remove-filter', searchFilterItem)
			.addEventListener('click', delSearchFilterItem, false);
		$('#search-button').addEventListener('click', doSearch, false);

		var lr = document.createElement('script');
		lr.async = true;
		lr.src = 'http://' + document.domain + ':8080/livereload.js';
		$('head').appendChild(lr);
	}

	window.addEventListener('load', main, true);
})();
