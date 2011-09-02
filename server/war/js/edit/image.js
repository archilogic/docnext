var id;

$( document ).ready( function() {
    id = readCookie( "document_id" );

    DocumentService.getImageInfo( id , function( data ) {
        $( "#maxNumberOfLevel" ).val( data.maxNumberOfLevel );
    } );
} );

function save() {
    var id = readCookie( "document_id" );

    DocumentService.getImageInfo( id , function( data ) {
        data.maxNumberOfLevel = $( "#maxNumberOfLevel" ).val();

        DocumentService.setImageInfo( id , data , function() {
        } );
    } );
}
