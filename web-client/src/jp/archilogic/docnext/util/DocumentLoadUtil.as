package jp.archilogic.docnext.util {
    import __AS3__.vec.Vector;
    
    import com.adobe.serialization.json.JSON;
    
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    import jp.archilogic.docnext.helper.ContextMenuHelper;
    import jp.archilogic.docnext.service.DocumentService;
    import jp.archilogic.docnext.ui.PageComponent;
    import jp.archilogic.docnext.ui.ThumbnailComponent;
    
    import mx.containers.Canvas;
    import mx.controls.Alert;
    
    import org.osmf.media.LoadableElementBase;

    public class DocumentLoadUtil {
		
		private static const PAGE_TILE_SPAN : int = 512;
		
		private static function getPageBitmapData( lastPx : int, contentWidth : int, contentHeight : int , isUseActual : Boolean ) : BitmapData {
            if ( isUseActual ) {
                var realContentWidth : int = PAGE_TILE_SPAN * (lastPx + 1);
                var realContentHeight : int = contentHeight * realContentWidth / contentWidth;
                return new BitmapData(realContentWidth, realContentHeight);
            } else {
                return new BitmapData(contentWidth, contentHeight);
            }
        }

        public static function loadPageSource(docId : Number , index : int , level : int , contentWidth : int ,
                contentHeight : int , isUseActual : Boolean , loadCompleteHandler : Function ) : void {
			var px : int = 0;
			var py : int = 0;
			var lastPx : int;
			
			var lastPy : int;
            
            if ( isUseActual ) {
                var width : int = PAGE_TILE_SPAN;
                var height : int = contentHeight * width / contentWidth;
                
                var factor : int = Math.pow( 2 , level );
                
                lastPx = ( width * factor - 1 ) / PAGE_TILE_SPAN + 1;
                lastPy = ( height * factor - 1 ) / PAGE_TILE_SPAN + 1;
            } else {
                lastPx = ( contentWidth - 1 ) / PAGE_TILE_SPAN + 1;
                lastPy = ( contentHeight - 1 ) / PAGE_TILE_SPAN + 1;
            }

            lastPx--;
            lastPy--;

            var bitmapData : BitmapData = getPageBitmapData(lastPx , contentWidth, contentHeight , isUseActual );

            loadTiledPage(docId, index, level, bitmapData, px, py, lastPx, lastPy, loadCompleteHandler); 
        }

		private static function loadTiledPage(docId : int, 
											 index : int,
											 level : int,
											 bitmapData : BitmapData,
											 px : int,
											 py : int,
											 lastPx : int,
											 lastPy : int,
											 loadCompleteHandler : Function ) : void {
			
			DocumentService.getPageTexture( docId , index , level , px , py , function( result : ByteArray ) : void {
				
				var loader : Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function() : void {
					
					loader.removeEventListener(Event.COMPLETE, arguments.callee );
					
					var tx : int = px * PAGE_TILE_SPAN;
					var ty : int = py * PAGE_TILE_SPAN;
					bitmapData.draw(loader, new Matrix(1, 0, 0, 1, tx , ty ) );
                    //Alert.show("w : " + loader.width);
					
					if( px == lastPx && py == lastPy ) {
						loadCompleteHandler(bitmapData);
						return;
					}
					
					if( px  == lastPx ) {
						px = 0;
						py++;
					}
					else {
						px++;
					}
					loadTiledPage(docId, index, level, bitmapData, px, py, lastPx, lastPy, loadCompleteHandler); 
				});
				loader.loadBytes(result);
			});
			
		}
		
		public static function loadThumb(thumb : ThumbnailComponent, loadCompleteHandler : Function = null) : void {
			DocumentService.getThumb(thumb.docId, thumb.page, function(result : ByteArray ) : void {
				thumb.addEventListener(Event.COMPLETE, function() : void {
					thumb.removeEventListener(Event.COMPLETE, arguments.callee );
					
					if(loadCompleteHandler != null)	loadCompleteHandler(thumb);
				});
				thumb.loadData(result);
			});
		}

		
        private static function loadAnnotation( page : PageComponent ) : void {
            DocumentService.getAnnotation( page.docId , page.page , function( result : String ) : void {
                page.annotation = JSON.decode( result );
            } );
        }

        private static function loadImageText( page : PageComponent ) : void {
            DocumentService.getImageText( page.docId , page.page , function( text : String ) : void {
                page.text = text;

                //loadAnnotation( page );
            } );
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
    }
}