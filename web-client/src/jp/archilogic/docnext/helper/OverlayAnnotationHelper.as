package jp.archilogic.docnext.helper {
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import mx.events.CloseEvent;
    import mx.events.FlexEvent;
    import jp.archilogic.docnext.ui.PageComponent;

    public class OverlayAnnotationHelper {
        private static const ALPHA : Number = 0.2;

        public function OverlayAnnotationHelper( page : PageComponent , converter : Function ) {
            _page = page;
            _converter = converter;
        }

        private var _page : PageComponent;
        private var _converter : Function;
        private var _changePageHanlder : Function;

        public function set annotation( value : Array ) : * {
            for each ( var anno : Object in value ) {
                ( function( anno : Object ) : void {
                    var rect : Rectangle =
                        _converter( new Rectangle( anno.region.x , anno.region.y , anno.region.width ,
                                                   anno.region.height ) );

                    switch ( anno.action.action ) {
                        case 'URI':
                            addAnnotation( rect , function( e : MouseEvent ) : void {
                                e.stopPropagation();

                                navigateToURL( new URLRequest( anno.action.uri ) );
                            } );
                            break;
                        case 'GoToPage':
                            addAnnotation( rect , function( e : MouseEvent ) : void {
                                e.stopPropagation();

                                Alert.show( 'May I jump to the page?' , 'Confirm' , Alert.YES | Alert.NO , null ,
                                            function( e_ : CloseEvent ) : void {
                                    if ( e_.detail == Alert.YES ) {
                                        // change to 0-origin
                                        _changePageHanlder( anno.action.page - 1 );
                                    }
                                } );
                            } );
                            break;
                        default:
                            throw new Error();
                    }
                } )( anno );
            }
        }

        public function set changePageHelper( value : Function ) : * {
            _changePageHanlder = value;
        }

        private function addAnnotation( rect : Rectangle , clickHandler : Function ) : void {
            var indicator : Canvas = new Canvas();
            indicator.x = rect.x;
            indicator.y = rect.y;
            indicator.width = rect.width;
            indicator.height = rect.height;
            indicator.setStyle( 'backgroundColor' , 0x000000 );
            indicator.alpha = ALPHA;

            if ( _page.hasCreationCompleted ) {
                _page.addChild( indicator );
            } else {
                _page.addEventListener( FlexEvent.CREATION_COMPLETE , function( e : FlexEvent ) : void {
                    _page.removeEventListener( FlexEvent.CREATION_COMPLETE , arguments.callee );

                    _page.addChild( indicator );
                } );
            }

            indicator.addEventListener( MouseEvent.CLICK , clickHandler );
        }
    }
}