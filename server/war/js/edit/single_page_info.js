var id = readCookie('document_id');
var spi;

$(document).ready(function(){
	DocumentService.getSinglePageInfo(id,
			  function(data) { setSPI(data);});
});

function setSPI(data) {
	spi = JSON.parse('[' + data + ']');
    for (var i = 0; i < spi.length; i++) {
	   addRow(spi[i]);
    }
}

function addRow(pageNumber) {
	if (pageNumber == null)
		pageNumber = $("#targetPage").val();
	$("#spi").append("<li><input type=\"checkbox\"><span class='pageNumber'>" + pageNumber + "</span> page</li>")
	//save();
}

function removeRow() {
	$("#spi > li > :checkbox[checked=true]").parent().remove();
	save();
}

var spi_save;
function save() {
	dom = $("#spi > li > span").contents().map(function(){return parseInt(this.data);});
	for (var key in dom)
		spi[key] = dom[key];
	spi.sort();
	DocumentService.setSinglePageInfo(id, spi, function (){});
	//DocumentService.setSinglePageInfo(objectEval($("p200").value), objectEval($("p201").value), reply20);
}