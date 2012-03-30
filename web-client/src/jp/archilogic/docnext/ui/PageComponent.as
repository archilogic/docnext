package jp.archilogic.docnext.ui {
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import mx.controls.Image;
    import mx.events.FlexEvent;
    import __AS3__.vec.Vector;
    import jp.archilogic.docnext.helper.ContextMenuHelper;
    import jp.archilogic.docnext.helper.OverlayHelper;
    import jp.archilogic.docnext.util.DocumentLoadUtil;

    public class PageComponent extends Image {
        public function PageComponent( page : int ) {
            super();

            _overlayHelper = new OverlayHelper( this );
            _overlayHelper.page = page;

            addEventListener( FlexEvent.CREATION_COMPLETE , function( e : FlexEvent ) : void {
                removeEventListener( FlexEvent.CREATION_COMPLETE , arguments.callee );

                _hasCreationCompleted = true;
            } );
        }

        private var _hasCreationCompleted : Boolean = false;
        private var _loaded : Boolean = false;
        private var _loading : Boolean = false;
        private var _overlayHelper : OverlayHelper;

        public function set annotation( value : Array ) : * {
            _overlayHelper.annotation = value;
        }

        public function get bitmapData() : BitmapData {
            return Bitmap( source ).bitmapData;
        }

        public function set changePageHandler( value : Function ) : * {
            _overlayHelper.changePageHandler = value;
        }

        public function changeSelectionToHighlight() : void {
            _overlayHelper.changeSelectionToHighlight();
        }

        public function clearEmphasize() : void {
            _overlayHelper.clearEmphasize();
        }

        public function set contextMenuHelper( value : ContextMenuHelper ) : void {
            _overlayHelper.contextMenuHelper = value;
        }

        public function get docId() : Number {
            return _overlayHelper.docId;
        }

        public function set docId( value : Number ) : * {
            _overlayHelper.docId = value;
        }

        public function getNearTextPos( point : Point ) : int {
            return _overlayHelper.getNearTextPos( point );
        }

        public function get hasCreationCompleted() : Boolean {
            return _hasCreationCompleted;
        }

        public function hasRegions() : Boolean {
            return _overlayHelper.hasRegions();
        }

        public function initSelection() : void {
            _overlayHelper.initSelection();
        }

        // TODO: misspell
        public function set isMenuVisbleFunc( value : Function ) : * {
            _overlayHelper.isMenuVisibleFunc = value;
        }

        public function loadAll( docId : Number , ratio : Number , level : int , size : Point ,
                                 contextMenuHelper : ContextMenuHelper , isMenuVisibleFunc : Function ,
                                 changePageHandler : Function , next : Function ) : void {
            _loading = true;

            this.docId = docId;
            this.ratio = ratio;
            this.contextMenuHelper = contextMenuHelper;
            this.isMenuVisbleFunc = isMenuVisibleFunc;
            this.changePageHandler = changePageHandler;

            var self : PageComponent = this;

            DocumentLoadUtil.loadPageSource( docId , _overlayHelper.page , level , size ,
                                             function( pageSource : BitmapData ) : void {
                loadData( pageSource );

                DocumentLoadUtil.loadRegions( self );

                next();
            } );
        }

        public function loadData( data : BitmapData ) : void {
            //var loader : Loader = new Loader();

            //loader.contentLoaderInfo.addEventListener( Event.COMPLETE , function() : void {
            //    loader.removeEventListener( Event.COMPLETE , arguments.callee );

            //var bd : BitmapData = new BitmapData( loader.width , loader.height );
            //bd.draw( loader );

            source = new Bitmap( data , 'auto' , true );

            width = data.width; //loader.width;
            height = data.height; //loader.height;

            dispatchEvent( new Event( Event.COMPLETE ) );

            _loaded = true;
            _loading = false;
            //} );

            //loader.loadBytes( data );
        }

        public function get loaded() : Boolean {
            return _loaded;
        }

        public function get loading() : Boolean {
            return _loading;
        }

        public function get page() : int {
            return _overlayHelper.page;
        }

        public function set page( value : int ) : * {
            _overlayHelper.page = value;
        }

        public function set ratio( value : Number ) : * {
            _overlayHelper.ratio = value;
        }

        public function set regions( value : Vector.<Rectangle> ) : * {
            _overlayHelper.regions = value;
        }

        public function get scale() : Number {
            return _overlayHelper.scale;
        }

        public function set scale( value : Number ) : * {
            _overlayHelper.scale = value;
        }

        public function get selectedText() : String {
            return _overlayHelper.selectedText;
        }

        public function showSelection( begin : int , end : int ) : void {
            _overlayHelper.showSelection( begin , end );
        }

        public function set text( value : String ) : * {
            _overlayHelper.text = value;
        }

        private function __registerClass__() : * {
            var __v__ : Vector;
            var __r__ : Rectangle;
        }
    }
}
