$(document).ready(function() {
    $("#edit_header").load("edit/menu.html", function() {
        $("a.navi").click(function(event) {
            var type = this.href.match(/([^\/.]*).html/)[1];
            loadPage(type);
            event.preventDefault();
        });
        loadPage("info");
    });
});

function loadPage(type) {
    // check
    updateDocInfo();
    
    var htmlPath = "edit/" + type + ".html";
    $("#content").load(htmlPath , function() {
        $.getScript("js/edit/" + type + ".js");
        
        $('.navi').css('color', 'rgb(0, 0, 255)');
        $('.navi[href*="/' + type + '.html"]').css('color', 'rgb(0, 0, 0)');
    });
}

function updateDocInfo() {
    var id = readCookie('document_id');
    $('#documentId').text(id);
}
