package jp.archilogic.docnext.ui {
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import jp.archilogic.docnext.helper.PageHeadHelper;
    import jp.archilogic.docnext.helper.ResizeHelper;
    
    import mx.collections.ArrayCollection;
    import mx.events.FlexEvent;
    import mx.events.ScrollEvent;
    import mx.utils.ObjectUtil;
    
    import spark.components.Group;
    import spark.events.GridEvent;

    public class TOCComponent extends Group {

        public function TOCComponent() {
            this._ui = new TOCComponentUI();
            this._ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            this.addElement( _ui );
        }

        private var _buttonPages : Vector.<int>;
        private var _changePageHandler : Function;
        private var _documentComponent : DocumentComponent;
        private var _infos : Vector.<Object>;
        private var _index : int;
        private var _isFocus : Boolean = true;
        private var _pageHeadHelpders : Vector.<PageHeadHelper>;
        private var _pages : Vector.<int>;
        private var _tocs : ArrayCollection;
        private var _totalPage : int;
        private var _ui : TOCComponentUI;

        public function set changePageHandler( value : Function ) : void {
            this._changePageHandler = value;
        }

        public function set documentComponent( d : DocumentComponent ) : void {
            this._documentComponent = d;
        }

        public function showUp() : void {
            this.visible = true;
            this._infos = _documentComponent.jsonInfos;
            this._pageHeadHelpders = _documentComponent.pageHeadHelpders;

            _pages = new Vector.<int>( this._pageHeadHelpders.length );
            _totalPage = 0;
            for ( var i : int = 0, n : int = this._pageHeadHelpders.length ; i < n ; i++ ) {
                var p : PageHeadHelper = this._pageHeadHelpders[ i ];
                _pages[ i ] = p.length;
                _totalPage += p.length;
            }

            initChildren();
            resizeHandler();
        }

        private function close( e : MouseEvent = null ) : void {
            this.visible = false;
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.removeEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            new ResizeHelper( this , resizeHandler );
            this.addEventListener( MouseEvent.CLICK , close );
            this._ui.dataGrid.addEventListener( GridEvent.GRID_CLICK , tocClick );
            this.percentWidth = 100;
            this.percentHeight = 100;
        }

        private function initChildren() : void {
            _tocs = new ArrayCollection();
            var pageCount : int = 0;
            for ( var i : int = 0 , n : int = this._infos.length ; i < n ; i++ ) {
                var info : Object = this._infos[ i ];
                var tocs : ArrayCollection = info.toc;
                
                for each ( var toc : Object in tocs ) {
                    var t : TOC = new TOC();
                    t.nameLabel = toc.text;
                    t.pageLabel = String( toc.page + pageCount );
                    t.page = toc.page;
                    t.pos = i;
                    _tocs.addItem( t );
                }
                
                pageCount += info.pages;
            }
            this._ui.dataGrid.dataProvider = _tocs;
        }
        
        private function resizeHandler() : void {
            if ( !visible ) {
                return;
            }

            this._ui.x = ( this.stage.stageWidth - this._ui.width ) / 2;
            this._ui.y = ( this.stage.stageHeight - this._ui.height ) / 2;
        }
        
        private function tocClick( e : GridEvent ) : void {
            if ( e.item is TOC ) {
                var t : TOC = TOC( e.item );
                this.close();
                this._changePageHandler( t.page , t.pos );
            }
        }
    }
}

class TOC {
    public var nameLabel : String;
    public var pageLabel : String;
    public var page : int;
    public var pos : int;
}