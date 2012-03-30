package jp.archilogic.docnext.util {
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import __AS3__.vec.Vector;
    import jp.archilogic.docnext.helper.ContextMenuHelper;
    import jp.archilogic.docnext.service.DocumentService;
    import jp.archilogic.docnext.ui.DocumentComponent;
    import jp.archilogic.docnext.ui.PageComponent;
    import jp.archilogic.docnext.ui.ThumbnailComponent;
    import org.osmf.media.LoadableElementBase;

    public class DocumentLoadUtil {
        public static function loadPageSource( docId : Number , index : int , level : int , size : Point ,
                                               loadCompleteHandler : Function ) : void {
            var nx : int = ( size.x - 1 ) / DocumentComponent.TEXTURE_SIZE + 1;
            var ny : int = ( size.y - 1 ) / DocumentComponent.TEXTURE_SIZE + 1;
            var bd : BitmapData = new BitmapData( size.x , size.y );

            loadTiledPage( docId , index , level , bd , 0 , 0 , nx , ny , loadCompleteHandler );
        }

        public static function loadRegions( page : PageComponent ) : void {
            DocumentService.getRegions( page.docId , page.page , function( result : ByteArray ) : void {
                result.endian = Endian.LITTLE_ENDIAN;

                var regions : Vector.<Rectangle> = new Vector.<Rectangle>();

                while ( result.position < result.length ) {
                    var region : Rectangle =
                        new Rectangle( result.readDouble() , result.readDouble() , result.readDouble() ,
                                       result.readDouble() );

                    regions.push( region );
                }

                page.regions = regions;

                loadImageText( page );
            } );
        }

        public static function loadThumb( thumb : ThumbnailComponent , loadCompleteHandler : Function = null ) : void {
            DocumentService.getThumb( thumb.docId , thumb.page , function( result : ByteArray ) : void {
                thumb.addEventListener( Event.COMPLETE , function() : void {
                    thumb.removeEventListener( Event.COMPLETE , arguments.callee );

                    if ( loadCompleteHandler != null )
                        loadCompleteHandler( thumb );
                } );
                thumb.loadData( result );
            } );
        }

        private static function loadAnnotation( page : PageComponent ) : void {
            DocumentService.getAnnotation( page.docId , page.page , function( result : String ) : void {
                page.annotation = new Array( JSON.parse( result ) );
            } );
        }

        private static function loadImageText( page : PageComponent ) : void {
            DocumentService.getImageText( page.docId , page.page , function( text : String ) : void {
                page.text = text;

                //loadAnnotation( page );
            } );
        }

        private static function loadTiledPage( docId : int , index : int , level : int , bitmapData : BitmapData ,
                                               px : int , py : int , nx : int , ny : int ,
                                               loadCompleteHandler : Function ) : void {
            if ( py < ny ) {
                if ( px < nx ) {
                    DocumentService.getPageTexture( docId , index , level , px , py ,
                                                    function( result : ByteArray ) : void {
                        var loader : Loader = new Loader();
                        loader.contentLoaderInfo.addEventListener( Event.COMPLETE , function() : void {
                            loader.removeEventListener( Event.COMPLETE , arguments.callee );

                            var tx : int = px * DocumentComponent.TEXTURE_SIZE;
                            var ty : int = py * DocumentComponent.TEXTURE_SIZE;

                            bitmapData.draw( loader , new Matrix( 1 , 0 , 0 , 1 , tx , ty ) );

                            loadTiledPage( docId , index , level , bitmapData , px + 1 , py , nx , ny ,
                                           loadCompleteHandler );
                        } );

                        loader.loadBytes( result );
                    } );
                } else {
                    loadTiledPage( docId , index , level , bitmapData , 0 , py + 1 , nx , ny , loadCompleteHandler );
                }
            } else {
                loadCompleteHandler( bitmapData );
            }
        }
    }
}
