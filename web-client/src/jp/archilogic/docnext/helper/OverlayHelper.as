package jp.archilogic.docnext.helper {
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.SharedObject;
    import flash.utils.Dictionary;
    import mx.containers.Canvas;
    import mx.events.FlexEvent;
    import __AS3__.vec.Vector;
    import jp.archilogic.docnext.ui.Balloon;
    import jp.archilogic.docnext.ui.PageComponent;

    public class OverlayHelper {
        private static const ALPHA_EMPHASIZE : Number = 0.8;
        private static const ALPHA_NORMAL : Number = 0.3;
        private static const KEY_BOTTOM : String = 'bottom';
        private static const KEY_LEFT : String = 'left';
        private static const KEY_RIGHT : String = 'right';
        private static const KEY_TOP : String = 'top';

        public function OverlayHelper( container : PageComponent ) {
            _container = container;

            _annotationHelper = new OverlayAnnotationHelper( container , convertToStageRect );
        }

        private var _annotationHelper : OverlayAnnotationHelper;
        private var _balloons : Dictionary /* of <int,Balloon> */ = new Dictionary();
        private var _bar : Number = 0;
        private var _container : PageComponent;
        private var _contextMenuHelper : ContextMenuHelper;
        private var _currentHighlightIndex : int = -1;
        private var _currentSelectionBegin : int;
        private var _currentSelectionEnd : int;
        private var _currentSelections : Dictionary /* of Indicator */;
        private var _docId : Number;
        private var _foo : Number = 0;
        private var _highlightInfos : Vector.<Object> /* of Object{begin,end,color,comment} */ = new Vector.<Object>();
        private var _highlights : Dictionary /* of <int,Dictionary<int,Indicator>> */ = new Dictionary();
        private var _isMenuVisibleFunc : Function;
        private var _level : int;
        private var _page : int;
        private var _ratio : Number;
        private var _regions : Vector.<Rectangle> = null;
        private var _scale : Number;
        private var _text : String;

        public function set annotation( value : Array ) : * {
            _annotationHelper.annotation = value;
        }

        public function changeHighlightColor( color : uint ) : void {
            _highlightInfos[ _currentHighlightIndex ].color = color;

            saveState();

            for each ( var indicator : Canvas in _highlights[ _currentHighlightIndex ] ) {
                indicator.setStyle( 'backgroundColor' , color );
            }
        }

        public function changeHighlightComment( comment : String ) : void {
            _highlightInfos[ _currentHighlightIndex ].text = comment;

            saveState();

            if ( _balloons[ _currentHighlightIndex ] ) {
                _container.removeChild( _balloons[ _currentHighlightIndex ] );
                delete _balloons[ _currentHighlightIndex ];
            }

            if ( comment.length > 0 ) {
                addBalloon( comment , _currentHighlightIndex );
            }
        }

        public function set changePageHandler( value : Function ) : * {
            _annotationHelper.changePageHelper = value;
        }

        public function changeSelectionToHighlight() : void {
            var info : Object =
                { begin: _currentSelectionBegin , end: _currentSelectionEnd , color: 0x0000ff , text: '' };

            _highlightInfos.push( info );

            saveState();

            var index : int = _highlightInfos.length - 1;

            addHighlight( info , index );

            initSelection();

            emphasizeHighlight( index );
            _currentHighlightIndex = index;
            _contextMenuHelper.showHighlightContextMenu( this , '' , dismissContextMenuFunc );
        }

        public function clearEmphasize() : void {
            emphasizeHighlight( -1 );
        }

        public function set contextMenuHelper( value : ContextMenuHelper ) : * {
            _contextMenuHelper = value;
        }

        public function get docId() : Number {
            return _docId;
        }

        public function set docId( value : Number ) : * {
            _docId = value;
        }

        public function getNearTextPos( point : Point ) : int {
            var t : Number = new Date().time;

            var minDist : Number = Number.MAX_VALUE;
            var minIndex : int = -1;

            for ( var index : int = 0 ; index < _regions.length ; index++ ) {
                var rect : Rectangle = _regions[ index ];

                var dist : Number =
                    Math.pow( point.x - ( rect.x + rect.width / 2 ) ,
                              2 ) + Math.pow( point.y - ( rect.y + rect.height / 2 ) , 2 );

                if ( dist < minDist ) {
                    minDist = dist;
                    minIndex = index;
                }
            }

            _foo += new Date().time - t;

            return minIndex;
        }

        public function hasRegions() : Boolean {
            return _regions != null;
        }

        public function hasSelectedText() : Boolean {
            return _currentSelectionBegin != -1 && _currentSelectionEnd != -1;
        }

        public function initSelection() : void {
            for each ( var indicator : Canvas in _currentSelections ) {
                _container.removeChild( indicator );
            }
            _currentSelections = null;

            _currentSelectionBegin = -1;
            _currentSelectionEnd = -1;
        }

        public function set isMenuVisibleFunc( value : Function ) : * {
            _isMenuVisibleFunc = value;
        }

        public function get level() : int {
            return _level;
        }

        public function set level( value : int ) : void {
            _level = value;
        }

        public function get page() : int {
            return _page;
        }

        public function set page( value : int ) : * {
            _page = value;
        }

        public function set ratio( value : Number ) : * {
            _ratio = value;
        }

        public function set regions( value : Vector.<Rectangle> ) : * {
            _regions = new Vector.<Rectangle>();

            var i : int = 0;

            for each ( var rect : Rectangle in value ) {
                var region : Rectangle = convertToStageRect( rect );
                _regions.push( region );
            }

            /*if ( i > 0 ) {
               _highlightInfos.push( { begin: 0 , end: 10 , color: 0x0000ff , text: '' } );
               saveState();
             }*/

            loadState();
        }

        public function removeHighlight() : void {
            _highlightInfos[ _currentHighlightIndex ] = null;
            delete _highlightInfos[ _currentHighlightIndex ];

            saveState();

            for each ( var indicator : Canvas in _highlights[ _currentHighlightIndex ] ) {
                _container.removeChild( indicator );
            }

            _highlights[ _currentHighlightIndex ] = null;
            delete _highlights[ _currentHighlightIndex ];

            if ( _balloons[ _currentHighlightIndex ] ) {
                _container.removeChild( _balloons[ _currentHighlightIndex ] );
                _balloons[ _currentHighlightIndex ] = null;
                delete _balloons[ _currentHighlightIndex ];
            }

            _currentHighlightIndex = -1;
        }

        public function get scale() : Number {
            return _scale;
        }

        public function set scale( value : Number ) : * {
            _scale = value;

            for each ( var balloon : Balloon in _balloons ) {
                balloon.adjust( _scale );
            }
        }

        public function get selectedText() : String {
            return _text.substring( _currentSelectionBegin , _currentSelectionEnd );
        }

        public function showSelection( begin : int , end : int ) : void {
            var t : Number = new Date().time;

            if ( !hasSelectedText() ) {
                _currentSelections = new Dictionary();

                addSelection( begin , end );
            } else {
                if ( begin < _currentSelectionBegin ) {
                    addSelection( begin , _currentSelectionBegin );
                } else if ( begin > _currentSelectionBegin ) {
                    removeSelection( _currentSelectionBegin , begin );
                }

                if ( end > _currentSelectionEnd ) {
                    addSelection( _currentSelectionEnd , end );
                } else if ( end < _currentSelectionEnd ) {
                    removeSelection( end , _currentSelectionEnd );
                }
            }
            _currentSelectionBegin = begin;
            _currentSelectionEnd = end;

            _bar += new Date().time - t;

            trace( 'TiledLoader.Selection.Indicator.Prof.foo.bar' , _foo , _bar );
        }

        public function set text( value : String ) : * {
            _text = value;
        }

        private function addBalloon( comment : String , index : int ) : void {
            var met : Object = calcHighlightMetrics( index );
            var tip : Point = new Point( ( met[ KEY_LEFT ] + met[ KEY_RIGHT ] ) / 2.0 , met[ KEY_TOP ] );

            var balloon : Balloon = new Balloon( comment );
            balloon.parentTip = tip;
            balloon.adjust( _scale );

            if ( _container.hasCreationCompleted ) {
                _container.addChild( balloon );
            } else {
                _container.addEventListener( FlexEvent.CREATION_COMPLETE , function( e : FlexEvent ) : void {
                    _container.removeEventListener( FlexEvent.CREATION_COMPLETE , arguments.callee );

                    _container.addChild( balloon );
                } );
            }

            _balloons[ index ] = balloon;
        }

        private function addHighlight( info : Object , index : int ) : void {
            _highlights[ index ] = new Dictionary();

            var self : OverlayHelper = this;
            addOverlay( info.begin , info.end , info.color , _highlights[ index ] , function( e : MouseEvent ) : void {
                if ( !_isMenuVisibleFunc() ) {
                    e.stopPropagation();

                    emphasizeHighlight( index );
                    _currentHighlightIndex = index;

                    _contextMenuHelper.showHighlightContextMenu( self ,
                                                                 _balloons[ _currentHighlightIndex ] ? _balloons[ _currentHighlightIndex ].text : '' ,
                                                                 dismissContextMenuFunc );
                }
            } );

            if ( info.text ) {
                addBalloon( info.text , index );
            }
        }

        private function addOverlay( begin : int , end : int , color : uint , holder : Dictionary = null ,
                                     clickHandler : Function = null ) : void {
            for ( var index : int = begin ; index < end ; index++ ) {
                var rect : Rectangle = _regions[ index ];

                var indicator : Canvas = new Canvas();
                indicator.x = rect.x;
                indicator.y = rect.y;
                indicator.width = rect.width;
                indicator.height = rect.height;
                indicator.setStyle( 'backgroundColor' , color );
                indicator.alpha = ALPHA_NORMAL;

                if ( _container.hasCreationCompleted ) {
                    _container.addChild( indicator );
                } else {
                    ( function( indicator_ : Canvas ) : void {
                        _container.addEventListener( FlexEvent.CREATION_COMPLETE , function( e : FlexEvent ) : void {
                            _container.removeEventListener( FlexEvent.CREATION_COMPLETE , arguments.callee );

                            _container.addChild( indicator_ );
                        } );
                    } )( indicator );
                }

                if ( holder != null ) {
                    holder[ index ] = indicator;
                }

                if ( clickHandler != null ) {
                    indicator.addEventListener( MouseEvent.CLICK , clickHandler );
                }
            }
        }

        private function addSelection( begin : int , end : int ) : void {
            addOverlay( begin , end , 0xff0000 , _currentSelections );
        }

        private function calcActualRect() : Rectangle {
            var ret : Rectangle = new Rectangle( 0 , 0 , _container.width , _container.height );

            if ( ret.width < ret.height * _ratio ) {
                // fit to width
                ret.y = ( ret.height - ret.width / _ratio ) / 2.0;
                ret.height = ret.width / _ratio;
            } else {
                // fit to height
                ret.x = ( ret.width - ret.height * _ratio ) / 2.0;
                ret.width = ret.height * _ratio;
            }

            return ret;
        }

        private function calcHighlightMetrics( index : int ) : Object {
            var ret : Object = {};
            ret[ KEY_TOP ] = Number.MAX_VALUE;
            ret[ KEY_BOTTOM ] = Number.MIN_VALUE;
            ret[ KEY_LEFT ] = Number.MAX_VALUE;
            ret[ KEY_RIGHT ] = Number.MIN_VALUE;

            for each ( var indicator : Canvas in _highlights[ index ] ) {
                ret[ KEY_TOP ] = Math.min( ret[ KEY_TOP ] , indicator.y );
                ret[ KEY_BOTTOM ] = Math.max( ret[ KEY_BOTTOM ] , indicator.y + indicator.height );
                ret[ KEY_LEFT ] = Math.min( ret[ KEY_LEFT ] , indicator.x );
                ret[ KEY_RIGHT ] = Math.max( ret[ KEY_RIGHT ] , indicator.x + indicator.width );
            }

            return ret;
        }

        private function convertToStageRect( rect : Rectangle ) : Rectangle {
            var actual : Rectangle = calcActualRect();

            return new Rectangle( actual.x + rect.x * actual.width , actual.y + rect.y * actual.height ,
                                  rect.width * actual.width , rect.height * actual.height );
        }

        private function dismissContextMenuFunc() : void {
            clearEmphasize();

            _contextMenuHelper.removeHighlightContextMenu();
        }

        private function emphasizeHighlight( targetIndex : int ) : void {
            for ( var key : String in _highlights ) {
                var index : int = parseInt( key );

                for each ( var indicator : Canvas in _highlights[ index ] ) {
                    indicator.alpha = index == targetIndex ? ALPHA_EMPHASIZE : ALPHA_NORMAL;
                }
            }
        }

        private function loadState() : void {
            var so : SharedObject = SharedObject.getLocal( 'so' );

            if ( !so.data[ 'highlight' ] ) {
                so.data[ 'highlight' ] = {};
            }

            if ( !so.data[ 'highlight' ][ _docId ] ) {
                so.data[ 'highlight' ][ _docId ] = {};
            }

            if ( !so.data[ 'highlight' ][ _docId ][ _page ] ) {
                so.data[ 'highlight' ][ _docId ][ _page ] = [];
            }

            _highlightInfos = new Vector.<Object>();

            for each ( var info : Object in so.data[ 'highlight' ][ _docId ][ _page ] ) {
                _highlightInfos.push( info );
                addHighlight( info , _highlightInfos.length - 1 );
            }
        }

        private function removeSelection( begin : int , end : int ) : void {
            for ( var index : int = begin ; index < end ; index++ ) {
                _container.removeChild( _currentSelections[ index ] );
                delete _currentSelections[ index ];
            }
        }

        private function saveState() : void {
            var so : SharedObject = SharedObject.getLocal( 'so' );

            // repack
            var data : Vector.<Object> = new Vector.<Object>();

            for each ( var info : Object in _highlightInfos ) {
                if ( info ) {
                    data.push( info );
                }
            }

            so.data[ 'highlight' ][ _docId ][ _page ] = data;

            so.flush();
        }
    }
}
