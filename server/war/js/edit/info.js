var id;

$( document ).ready( function() {
    id = readCookie( "document_id" );

    DocumentService.getInfo( id , function( data ) {
        $( "#title" ).val( data.title );
        $( "#publisher" ).val( data.publisher );

        $( "#binding_left" ).attr( "checked" , data.binding == BindingType.LEFT );
        $( "#binding_right" ).attr( "checked" , data.binding == BindingType.RIGHT );

        $( "#flow_left" ).attr( "checked" , data.flow == FlowDirectionType.TO_LEFT );
        $( "#flow_right" ).attr( "checked" , data.flow == FlowDirectionType.TO_RIGHT );
    } );
} );

function save() {
    var id = readCookie( "document_id" );

    DocumentService.getInfo( id , function( data ) {
        data.title = $( "#title" ).val();
        data.publisher = $( "#publisher" ).val();
        data.binding = $( "#binding_left" ).attr( "checked" ) ? BindingType.LEFT : BindingType.RIGHT;
        data.flow = $( "#flow_left" ).attr( "checked" ) ? FlowDirectionType.TO_LEFT : FlowDirectionType.TO_RIGHT;

        DocumentService.setInfo( id , data , function() {
        } );
    } );
}
