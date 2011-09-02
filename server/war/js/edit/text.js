window.onload = function() {
	updateText();
}

function updateText() {
	var id = readCookie('document_id');
	var page = document.getElementById('page').value;

	DocumentService.getText(id, page, function(data) {
		document.getElementById('text').value = data;
	});
}

function save() {
	var id = readCookie('document_id');
	var page = document.getElementById('page').value;
	var text = document.getElementById('text').value;

	DocumentService.setText(id, page, text, function(data) {
	});
}
