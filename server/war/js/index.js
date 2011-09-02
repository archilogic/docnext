/**
 * 
 */
$(document).ready(function() {
    $("a.navi").click(function(event) {
        var type = this.href.match(/([^\/.]*).html/)[1];
        loadPage(type);
        event.preventDefault();
    });
});

function loadPage(type) {
    
    var htmlPath = type + ".html";
    $("#content").load(htmlPath , function() {
        $.getScript("js/" + type + ".js");
        
        $('.navi').css('color', 'rgb(0, 0, 255)');
        $('.navi[href*="/' + type + '.html"]').css('color', 'rgb(0, 0, 0)');
    });
}

$(document).ready(function() {
    getDataFromServer();
});

function getDataFromServer() {
    DocumentService.findAll({
        callback : getDataFromServerCallBack
    });
}

function moveToEdit(id) {
    var str = "document_id";
    createCookie(str, id.toString(10), 1);

    window.location.href = "edit.html";
}

function getDataFromServerCallBack(dataFromServer) {
    for ( var i = 0; i < dataFromServer.length; i++) {
        var id = dataFromServer[i].id;
        var name = dataFromServer[i].name;

        var divContent = "<input type='button' value='" + name + id + "'"
                + " onclick='moveToEdit(" + id + ")'" + ">";
        $("#divTxt").append(divContent);
    }
}
