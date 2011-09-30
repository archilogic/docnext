package jp.archilogic.docnext.ui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import jp.archilogic.docnext.helper.OverlayHelper;
	
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.events.FlexEvent;
	public class ThumbnailComponent extends Image
	{
		public function ThumbnailComponent()
		{
			super();
			
			 this.addEventListener( FlexEvent.CREATION_COMPLETE , function( e : FlexEvent ) : void {
                removeEventListener( FlexEvent.CREATION_COMPLETE , arguments.callee );

                
            } ); 
            /* this.addEventListener( Event.REMOVED, function(e : Event) : void
            {
            	Alert.show('removed');
            }); */
		}
		
		/* private var _hasCreationCompleted : Boolean = false; */
		private var _overlayHelper : OverlayHelper;
		public function get bitmapData() : BitmapData {
            return Bitmap( source ).bitmapData;
        }
        private var _ratio : Number = 0.3;
        private var _docId : int = 2;
        private var _page  : int = 3;
        private var thumbSource :BitmapData;
        public function set ratio(ratio : Number):void{this._ratio=ratio;}
        public function set docId(docId : int):void{this._docId=docId;}
        public function set page(page : int):void{this._page=page;}
        public function get ratio() : Number{return _ratio;}
        public function get docId() : int { return _docId;}
        public function get page() : int { return _page ;}
        /* public function get hasCreationCompleted() : Boolean {
            return _hasCreationCompleted;
        } */
		public function setNullSources() : void
		{
			this.thumbSource = null;
			this.source = null;
		}
        public function hasThumbSource() : Boolean
        {
        	var value : Boolean = false;
        	if( thumbSource != null) value = true;
        	return value;
        }
        public function resetThumbSource() : void
        {
        	/* this.source = null; */
        	this.source = new Bitmap(thumbSource); 
			
        }
		
        public function loadData( data : ByteArray ) : void 
        {
            var loader : Loader = new Loader();
            
            loader.contentLoaderInfo.addEventListener( Event.COMPLETE , function() : void 
            {
                loader.removeEventListener( Event.COMPLETE , arguments.callee );

                var bd : BitmapData = new BitmapData( loader.width , loader.height );
                bd.draw( loader );
                var bitmap : Bitmap = new Bitmap(bd);
            	source = bitmap;
            	/* width = bd.width;
           	 	height = bd.height; */
           	 	thumbSource = bd;
                /* Alert.show("width : " + width + "   height : " + loader.height);   */
				/* _hasCreationCompleted = true; */
                dispatchEvent( new Event( Event.COMPLETE ) );
            } );
            loader.loadBytes( data );
        }
       

	}
}