var MULTIPLE_DOCUMENTS = 2;
var _text; // there should be something better method.
var _ids;
var _correctIds;

$(document).ready(function(){
	addRow();
});

function addRow() {
    var thumbColumn = "<td></td>"
	var nameColumn = "<td class='name'>name</td>"
	var idColumn = "<td><input type='text' class='documentId' onblur='validateId(this)'></td>";
	var deleteColumn = "<td><input type='button' value='-' onclick='deleteRow(this)'></td>";
	var rowTag = "<tr>" + nameColumn + idColumn + deleteColumn + "</tr>";
	$("#documentIds").append(rowTag);
}

function createDocument(ids) {
	var array = "";
	for (var i = 0; i < ids.length; i++) {
		array += ids[i];
		if (i != ids.length - 1) {
			array += ",";
		}
	}
	var type = MULTIPLE_DOCUMENTS;
	var json = '{types:[' + type + '], ids:[' + array + ']}';
	var done = function(id) {
		confirm("document was created with id:" + id);
	}
	DocumentService.createDocument(json, done);
}

function deleteRow(button) {
	row = button.parentNode.parentNode;
	tbody = row.parentNode;
	tbody.removeChild(row);
}

function error(msg) {
	alert(msg);
}

function isValidDocument(doc) {
	if (doc == null) {
		error("invalid document id");
 		return false;
	}
	if (doc.types[0] == MULTIPLE_DOCUMENTS) {
		error("invalid document id");
		return false;
	}
	return true;
}

function publish() {
	_ids = $('.documentId').map(function(){ return this.value; });
	_correctIds = new Array();
	
	for (var i = 0; i < _ids.length; i++) {
		DocumentService.getDocument( _ids[i], validateDocument);
	}
}

function warning(msg) {
	confirm(msg);
}

function validateId(text) {
	_text = text;
	var id = text.value;
	if (id == null || id == '') {
		warning('document id is blank');
	}
	DocumentService.getDocument(id, validateIdCallback);
}

function validateIdCallback(json) {
    var doc = JSON.parse(json);
	if (isValidDocument(doc)) {
		_text.parentNode.parentNode.firstChild.textContent = doc.name; 
	}
}

function validateDocument(json) {
    var doc = JSON.parse(json);
	if (!isValidDocument(doc)) {
		return;
	}
	
	_correctIds[_correctIds.length] = doc.id;
	if (_correctIds.length == _ids.length) {
		createDocument(_correctIds);
	}
	return true;
}
