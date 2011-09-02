$(document).ready(function(){
	DocumentService.getTOC(id, setTOC);
});

function setTOC(tocs) {
	tocs.forEach(function(part){
		addRow({title:part.text, page:part.page});
	})
	if (tocs.length == 0)
	    addRow();
}

function addRow(part) {
	if (part == null)
		part = {title:"", page:0};
	var titleColumn = "<td><input type='text' class='title' style='width:97%;' value='" + part.title + "'></td>";
	var pageColumn = "<td><input type='text' class='page' style='width:80%;' value='" + part.page + "'></td>";
	var deleteColumn = "<td><input type='button' value='-' onclick='deleteRow(this);'></td>"
	
	$("#tableOfContents").append("<tr>" + titleColumn + pageColumn +  deleteColumn + "</tr>");
}

function deleteRow(button) {
	row = button.parentNode.parentNode
	row.parentNode.removeChild(row);
} 

function save() {
    var tableOfContents = [];
	var titles = $(".title").map(function(){ return this.value;});
	var pages = $(" .page").map(function(){ return parseInt(this.value);});
	for (var i = 0; i < pages.length; i++) {
		tableOfContents[i] = {page:pages[i], text:titles[i]};
	}
	function compare(a, b){
		if (a.page < b.page) return -1;
		if (a.page > b.page) return 1;
		return 0;
	}
	tableOfContents.sort(compare);
	DocumentService.setTOC(id, tableOfContents, function() {});
}
