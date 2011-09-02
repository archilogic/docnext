var id = readCookie('document_id');

$(document).ready(function(){
	DocumentService.getDividePage(id, setDividePage);
});

function setDividePage(data) {
    for (var i = 0; i < data.length; i++) {
	   addRow({page:data[i].page, number:data[i].number});
    }
}

function addRow(dividePage) {
	if (dividePage== null)
		dividePage = {page: $("#page").val(), number:$("#division").val()};
	$("#dividePage").append("<tr><td><input type='checkbox'></td>" +
			                "<td class='page'>" + dividePage.page + "</td>" +
			                "<td class='number'>" + dividePage.number + "</td></tr>")
}

function removeRow() {
	$("#dividePage :checkbox[checked=true]").parent().parent().remove();
}

function save() {
    var dividePageArray = [];
	var pages = $("#dividePage .page").contents().map(function(){return parseInt(this.data);});
	var numbers = $("#dividePage .number").contents().map(function(){return parseInt(this.data);});
	for (var i = 0; i < pages.length; i++) {
		dividePageArray[i] = {page:pages[i], number:numbers[i]};
	}

	DocumentService.setDividePage(id, dividePageArray, function() {});
}
