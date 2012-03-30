package jp.archilogic.docnext.ui
{
    import flash.display.BitmapData;
    
    import jp.archilogic.docnext.util.DocumentLoadUtil;
    
    import mx.controls.Alert;
    import mx.controls.Image;

    
    public class Thumbnail extends Image
    {
        private static const SHELFED_HEIGHT : int = 100 * 2;
        private static const SHELFED_WIDTH : int = 60 * 2;
 
        private var thumb : ThumbnailComponent;
        
        public var _page : Number = -1;
        public var _docId : Number = -1;
        
        public function Thumbnail()
        {
            super();
            
            thumb = new ThumbnailComponent();
            
            thumb.docId = 1723;
            thumb.width = SHELFED_WIDTH;
            thumb.height = SHELFED_HEIGHT;
            thumb.x = 0;
            thumb.y = 0;
            thumb.source = new BitmapData( SHELFED_WIDTH , SHELFED_HEIGHT , false , 0x334433 )
            thumb.visible = true;
        }
        
        private function reload() : void {
            thumb.page = _page;
            thumb.docId = _docId;
            
            if ( _page == -1 || _docId == -1 ) {
                return;
            }
            
            DocumentLoadUtil.loadThumb( thumb , null );
            this.source = thumb;
            addChild( thumb );
        }
        
        public function get page() : Number {
            return _page;
        }
        
        public function set page( value : Number ) : void {
            _page = value;
            reload();
        }
        
        public function get docId() : Number {
            return _docId;
        }
        
        public function set docId( value : Number ) : void {
            _docId = value;
            reload();
        }
    }
}