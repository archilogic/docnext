package jp.archilogic.docnext.ui {
    import com.foxaweb.pageflip.PageFlip;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import mx.collections.ArrayCollection;
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import mx.controls.ProgressBar;
    import mx.controls.ProgressBarLabelPlacement;
    import mx.core.IIMESupport;
    import mx.core.UIComponent;
    import mx.events.FlexEvent;
    import mx.utils.ObjectUtil;
    import __AS3__.vec.Vector;
    import caurina.transitions.Tweener;
    import jp.archilogic.docnext.controller.ViewerController;
    import jp.archilogic.docnext.dto.DocumentResDto;
    import jp.archilogic.docnext.dto.DocumentResDto;
    import jp.archilogic.docnext.helper.ContextMenuHelper;
    import jp.archilogic.docnext.helper.ContextMenuHelper;
    import jp.archilogic.docnext.helper.DocumentMouseEventHelper;
    import jp.archilogic.docnext.helper.DocumentMouseEventHelper;
    import jp.archilogic.docnext.helper.PageHeadHelper;
    import jp.archilogic.docnext.helper.PageHeadHelper;
    import jp.archilogic.docnext.helper.ResizeHelper;
    import jp.archilogic.docnext.helper.ResizeHelper;
    import jp.archilogic.docnext.service.DocumentService;
    import jp.archilogic.docnext.service.DocumentService;
    import jp.archilogic.docnext.util.DocumentLoadUtil;
    import jp.archilogic.docnext.util.DocumentLoadUtil;

    public class DocumentComponent extends Canvas {
        public static const TEXTURE_SIZE : int = 512;
        private static const TEXTURE_LEVEL : int = 1;

        public function DocumentComponent() {
            _ui = new DocumentComponentUI();
            _ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            addChild( _ui );

            _contextMenuHelper = new ContextMenuHelper( this );

            _mouseEventHelper = new DocumentMouseEventHelper();
            _mouseEventHelper.contextMenuHelper = _contextMenuHelper;
            _mouseEventHelper.changePageFunc = changePageArrowClickHanlder;
            _mouseEventHelper.currentPagesFunc = getCurrentPages;
            _mouseEventHelper.zoomPageFunc = zoom;

            addEventListener( Event.ADDED_TO_STAGE , addToStageHandler );

            addEventListener( MouseEvent.CLICK , function() : void {
                view.bookmark.visible = false;
            } );
        }

        public var view : Viewer;

        private var _baseScale : Number;
        private var _contextMenuHelper : ContextMenuHelper;
        private var _currentDocPos : int;
        private var _currentHead : int;
        private var _dtos : Vector.<DocumentResDto>;
        private var _imageInfo : Object;
        private var _infos : Vector.<Object>;
        private var _isAnimating : Boolean;
        private var _loadQueue : Array = [];
        private var _loadingCount : int;
        private var _mouseEventHelper : DocumentMouseEventHelper;
        private var _pageHeadHelpers : Vector.<PageHeadHelper>;
        private var _pages : Vector.<Vector.<PageComponent>>;
        private var _setPageHandler : Function;
        private var _ui : DocumentComponentUI;
        private var _zoomExponent : int;
        private var progress : ProgressBar;

        public function addEvents() : void {
            //stage.addEventListener( KeyboardEvent.KEY_UP , myKeyUpHandler );
            resizeHandler();
        }

        public function get background() : Bitmap {
            var bd : BitmapData = new BitmapData( width , height );
            bd.draw( this );

            var bitmap : Bitmap = new Bitmap( bd );
            bitmap.width = this.width;
            bitmap.height = this.height;

            return bitmap;
        }

        public function calcMaxPageSize() : Point {
            return calcPageSize( _imageInfo.maxLevel );
        }

        public function calcThumbPageSize() : Point {
            return calcPageSize( 0 );
        }

        public function set changeMenuVisiblityHandler( value : Function ) : * {
            _mouseEventHelper.changeMenuVisiblityFunc = value;
        }

        public function get currentDocPos() : int {
            return _currentDocPos;
        }

        public function get currentHead() : int {
            return _currentHead;
        }

        public function set currentHead( value : int ) : * {
            _currentHead = value;

            var sumToCurrent : int = 0;
            var sumTotal : int = 0;

            for ( var index : int = 0 ; index < _infos.length ; index++ ) {
                if ( index < _currentDocPos ) {
                    sumToCurrent += _infos[ _currentDocPos ].pages;
                }

                sumTotal += _infos[ _currentDocPos ].pages;
            }

            _setPageHandler( currentPage + sumToCurrent , sumTotal );
        }

        public function set currentHeadByPage( page : int ) : void {
            _currentHead = _pageHeadHelpers[ _currentDocPos ].pageToHead( page );

            _ui.wrapper.removeAllElements();

            loadFullByPage( currentPage );
        }

        public function get currentPageByHead() : int {
            return _pageHeadHelpers[ _currentDocPos ].headToPage( _currentHead );
        }

        public function get currentPageHeadHelpder() : PageHeadHelper {
            return _pageHeadHelpers[ _currentDocPos ];
        }

        public function get docId() : int {
            return _dtos[ _currentDocPos ].id;
        }

        public function hasPage( currentDocPos : int , currentHead : int ) : Boolean {
            return _pages[ currentDocPos ][ currentHead ];
        }

        public function get imageInfo() : Object {
            return _imageInfo;
        }

        public function get isBindingRight() : Boolean {
            return _infos[ _currentDocPos ].binding == "RIGHT";
        }

        public function set isMenuVisibleHandler( value : Function ) : * {
            _mouseEventHelper.isMenuVisibleFunc = value;
        }

        public function get jsonInfos() : Vector.<Object> {
            return _infos;
        }

        public function load( dtos : Vector.<DocumentResDto> ) : void {
            _dtos = dtos;
            _infos = new Vector.<Object>( _dtos.length );
            _pageHeadHelpers = new Vector.<PageHeadHelper>( _dtos.length );
            _pages = new Vector.<Vector.<PageComponent>>( _dtos.length );

            loadHelepr( 0 );
        }

        public function get pageHeadHelpders() : Vector.<PageHeadHelper> {
            return _pageHeadHelpers;
        }

        public function get pages() : Vector.<PageComponent> {
            return _pages[ _currentDocPos ];
        }

        public function get ratio() : int {
            return _infos[ _currentDocPos ].ratio;
        }

        public function set selecting( value : Boolean ) : void {
            _mouseEventHelper.selecting = value;
        }

        public function setCurrentDocPos( pos : int , page : int = 0 ) : void {
            _currentDocPos = pos;
            _currentHead = _pageHeadHelpers[ pos ].pageToHead( page );

            _ui.wrapper.removeAllElements();

            loadFullByPage( currentPage );
        }

        public function set setPageHandler( value : Function ) : * {
            _setPageHandler = value;
        }

        /**
         * Unused
         */
        public function zoomIn() : void {
            _zoomExponent = Math.min( _zoomExponent + 1 , 6 );

            changeScale();
        }

        /**
         * Unused
         */
        public function zoomOut() : void {
            _zoomExponent = Math.max( _zoomExponent - 1 , 0 );

            changeScale();
        }

        private function addItemToLoadQueue( index : int ) : void {
            if ( index >= 0 && index < _infos[ _currentDocPos ].pages ) {
                if ( !pages[ index ] ) {
                    var pc : PageComponent = new PageComponent( index );

                    var sz : Point = calcMainPageSize();

                    pc.source = new Bitmap( new BitmapData( sz.x , sz.y ) , 'auto' , true );
                    pc.width = sz.x;
                    pc.height = sz.y;

                    pages[ index ] = pc;
                }

                _loadQueue.push( index );
            }
        }

        private function addPage( page : PageComponent , isFore : Boolean , next : Function = null ,
                                  hidden : Boolean = false ) : void {
            page.addEventListener( Event.ADDED_TO_STAGE , function() : void {
                page.removeEventListener( Event.ADDED_TO_STAGE , arguments.callee );

                page.callLater( function() : void {
                    // for layouting, maybe...
                    if ( isFore == isBindingRight ) {
                        page.x = page.contentWidth;
                    } else {
                        page.x = 0;
                    }

                    if ( next != null ) {
                        next( page );
                    }
                } );
            } );

            if ( hidden ) {
                _ui.wrapper.addElementAt( page , 0 );
            } else {
                _ui.wrapper.addElement( page );
            }
        }

        private function addToStageHandler( e : Event ) : void {
            this.removeEventListener( Event.ADDED_TO_STAGE , addToStageHandler );
//            stage.addEventListener( KeyboardEvent.KEY_UP , myKeyUpHandler );
//            stage.addEventListener( KeyboardEvent.KEY_DOWN , myKeyDownHandler );
        }

        private function calcBezierPoint( p0 : Point , p1 : Point , cp : Point , t : Number ) : Point {
            var v : Number = 1.0 - t;
            return new Point( v * v * p0.x + 2 * v * t * cp.x + t * t * p1.x ,
                              v * v * p0.y + 2 * v * t * cp.y + t * t * p1.y );
        }

        private function calcCenterX( contentWidth : Number , limit : Number = 0 ) : Number {
            return Math.max( ( _ui.arrowIndicator.width - contentWidth ) / 2 , limit );
        }

        private function calcCenterY( contentHeight : Number , limit : Number = 0 ) : Number {
            return Math.max( ( _ui.arrowIndicator.height - contentHeight ) / 2 , limit );
        }

        private function calcMainPageSize() : Point {
            return calcPageSize( TEXTURE_LEVEL );
        }

        private function calcPageSize( level : int ) : Point {
            var isUseActual : Boolean = _imageInfo.maxLevel == level && _imageInfo.isUseActualSize;

            if ( isUseActual ) {
                return new Point( _imageInfo.width , _imageInfo.height );
            } else {
                var factor : int = Math.pow( 2 , level );

                var width : int = TEXTURE_SIZE * factor;
                var height : int = _imageInfo.height * width / _imageInfo.width;
                return new Point( width , height );
            }
        }

        private function centering() : void {
            _ui.scroller.x = calcCenterX( _ui.wrapper.contentWidth * _ui.wrapper.scaleX );
            _ui.scroller.y = calcCenterY( _ui.wrapper.contentHeight * _ui.wrapper.scaleY );
        }

        private function changeHead( head : int ) : void {
            var nextDocPos : int = _currentDocPos;

            if ( head < 0 && _currentDocPos - 1 >= 0 ) {
                nextDocPos--;
                head += _pageHeadHelpers[ nextDocPos ].length;
            } else if ( head >= _pageHeadHelpers[ _currentDocPos ].length && _currentDocPos + 1 < _infos.length ) {
                nextDocPos++;
                head -= _pageHeadHelpers[ _currentDocPos ].length;
            }

            if ( !_pageHeadHelpers[ nextDocPos ].isValidHead( head ) ||
                nextDocPos == _currentDocPos && head == _currentHead || _isAnimating ) {
                return;
            }

            var isCurrentSingle : Boolean = _pageHeadHelpers[ _currentDocPos ].isSingleHead( _currentHead );
            var isNextSingle : Boolean = _pageHeadHelpers[ nextDocPos ].isSingleHead( head );

            if ( isCurrentSingle ) {
                if ( isNextSingle ) {
                    changePage1to1( head , nextDocPos );
                } else {
                    changePage1to2( head , nextDocPos );
                }
            } else {
                if ( isNextSingle ) {
                    changePage2to1( head , nextDocPos );
                } else {
                    changePage2to2( head , nextDocPos );
                }
            }
        }

        private function changePage1to1( head : int , docPos : int ) : void {
            var isForward : Boolean = docPos > _currentDocPos || docPos >= _currentDocPos && head > _currentHead;

            var prev : PageComponent = currentForePage;

            _currentDocPos = docPos;
            currentHead = head;
            var next : PageComponent = currentForePage;

            next.scale = _ui.wrapper.scaleX;

            var width : int = _ui.wrapper.contentWidth * _ui.wrapper.scaleX;

            if ( !isBindingRight ) {
                _ui.scroller.x -= width;
                prev.x = prev.contentWidth;
            }

            addPage( next , false , function( page : PageComponent ) : void {
                var back : PageComponent = isForward ? prev : next;
                var removeOnBegin : PageComponent = isForward ? prev : null;
                var removeOnEnd : PageComponent = isForward ? null : prev;

                isAnimating = true;

                startFlip( null , back , isForward , function() : void {
                    if ( removeOnBegin && _ui.wrapper.contains( removeOnBegin ) ) {
                        _ui.wrapper.removeElement( removeOnBegin );
                    }
                } , function() : void {
                    if ( removeOnEnd && _ui.wrapper.contains( removeOnEnd ) ) {
                        _ui.wrapper.removeElement( removeOnEnd );
                    }

                    next.initSelection();
                    next.clearEmphasize();

                    changePageCleanUp();

                    if ( !isBindingRight ) {
                        _ui.scroller.x += width;
                        next.x = 0;
                    }

                    isAnimating = false;
                } );
            } , true );
        }

        private function changePage1to2( head : int , docPos : int ) : void {
            var isForward : Boolean = docPos > _currentDocPos || docPos >= _currentDocPos && head > _currentHead;

            var prev : PageComponent = currentForePage;

            _currentDocPos = docPos;
            currentHead = head;
            var nextFore : PageComponent = currentForePage;
            var nextRear : PageComponent = currentRearPage;

            nextFore.scale = nextRear.scale = _ui.wrapper.scaleX;

            var width : int = _ui.wrapper.contentWidth * _ui.wrapper.scaleX;

            var dx : Number = calcCenterX( width * 2 ) - calcCenterX( width );

            var hide : PageComponent = isForward ? nextFore : nextRear;
            hide.visible = false;

            if ( isForward != isBindingRight ) {
                _ui.scroller.x -= width;
                prev.x = prev.contentWidth;
                dx += width;
            }

            addPage( nextFore , true , function( page : PageComponent ) : void {
                addPage( nextRear , false , function( page : PageComponent ) : void {
                    var front : PageComponent = isForward ? nextFore : prev;
                    var back : PageComponent = isForward ? prev : nextRear;

                    isAnimating = true;

                    startFlip( front , back , isForward , function() : void {
                        if ( _ui.wrapper.contains( prev ) ) {
                            _ui.wrapper.removeElement( prev );
                        }
                    } , function() : void {
                        nextFore.initSelection();
                        nextFore.clearEmphasize();
                        nextRear.initSelection();
                        nextRear.clearEmphasize();

                        changePageCleanUp();

                        hide.visible = true;

                        isAnimating = false;
                    } , dx );
                } , true );
            } , true );
        }

        private function changePage2to1( head : int , docPos : int ) : void {
            var isForward : Boolean = docPos > _currentDocPos || docPos >= _currentDocPos && head > _currentHead;

            var prevFore : PageComponent = currentForePage;
            var prevRear : PageComponent = currentRearPage;

            _currentDocPos = docPos;
            currentHead = head;
            var next : PageComponent = currentForePage;

            next.scale = _ui.wrapper.scaleX;

            var width : int = _ui.wrapper.contentWidth * _ui.wrapper.scaleX;

            var dx : Number = ( isForward == isBindingRight ? -1 : 1 ) * ( width / 2 / 2 );

            next.visible = false;

            addPage( next , !isBindingRight , function( page : PageComponent ) : void {
                var front : PageComponent = isForward ? next : prevFore;
                var back : PageComponent = isForward ? prevRear : next;
                var removeOnBegin : PageComponent = isForward ? prevRear : prevFore;
                var removeOnEnd : PageComponent = isForward ? prevFore : prevRear;

                isAnimating = true;

                startFlip( front , back , isForward , function() : void {
                    if ( _ui.wrapper.contains( removeOnBegin ) ) {
                        _ui.wrapper.removeElement( removeOnBegin );
                    }
                } , function() : void {
                    if ( _ui.wrapper.contains( removeOnEnd ) ) {
                        _ui.wrapper.removeElement( removeOnEnd );
                    }

                    next.initSelection();
                    next.clearEmphasize();

                    changePageCleanUp();

                    if ( isForward == isBindingRight ) {
                        _ui.scroller.x += width / 2;
                    }

                    next.visible = true;

                    isAnimating = false;
                } , dx );
            } , true );
        }

        private function changePage2to2( head : int , docPos : int ) : void {
            var isForward : Boolean = docPos > _currentDocPos || docPos >= _currentDocPos && head > _currentHead;

            var prevFore : PageComponent = currentForePage;
            var prevRear : PageComponent = currentRearPage;

            _currentDocPos = docPos;
            currentHead = head;
            var nextFore : PageComponent = currentForePage;
            var nextRear : PageComponent = currentRearPage;

            nextFore.scale = nextRear.scale = _ui.wrapper.scaleX;

            var hide : PageComponent = isForward ? nextFore : nextRear;
            hide.visible = false;

            addPage( nextFore , true , function( page : PageComponent ) : void {
                addPage( nextRear , false , function( page : PageComponent ) : void {
                    var front : PageComponent = isForward ? nextFore : prevFore;
                    var back : PageComponent = isForward ? prevRear : nextRear;
                    var removeOnBegin : PageComponent = isForward ? prevRear : prevFore;
                    var removeOnEnd : PageComponent = isForward ? prevFore : prevRear;

                    isAnimating = true;

                    startFlip( front , back , isForward , function() : void {
                        if ( _ui.wrapper.contains( removeOnBegin ) ) {
                            _ui.wrapper.removeElement( removeOnBegin );
                        }
                    } , function() : void {
                        if ( _ui.wrapper.contains( removeOnEnd ) ) {
                            _ui.wrapper.removeElement( removeOnEnd );
                        }

                        nextFore.initSelection();
                        nextFore.clearEmphasize();
                        nextRear.initSelection();
                        nextRear.clearEmphasize();

                        changePageCleanUp();

                        hide.visible = true;

                        isAnimating = false;
                    } );
                } , true );
            } , true );
        }

        private function changePageArrowClickHanlder( delta : int ) : void {
            if ( delta > 0 ) {
                moveLeft();
            } else {
                moveRight();
            }
        }

        private function changePageCleanUp() : void {
            loadNeighborPage();
        }

        private function changePageHandler( page : int ) : void {
            changeHead( _pageHeadHelpers[ _currentDocPos ].pageToHead( page ) );
        }

        private function changeScale() : void {
            var hPos : Number =
                _ui.wrapper.width > 0 ? ( _ui.wrapper.horizontalScrollPosition ) / _ui.wrapper.width : 0.5;
            var vPos : Number =
                _ui.wrapper.height > 0 ? ( _ui.wrapper.verticalScrollPosition ) / _ui.wrapper.height : 0.5;

            var scale : Number = _baseScale * Math.pow( 2 , _zoomExponent / 3.0 );

            _ui.wrapper.scaleX = _ui.wrapper.scaleY = scale;

            currentForePage.scale = scale;

            if ( currentRearPage ) {
                currentRearPage.scale = scale;
            }

            _ui.wrapper.callLater( function() : void {
                centering();

                _ui.wrapper.horizontalScrollPosition = hPos * _ui.wrapper.width;
                _ui.wrapper.verticalScrollPosition = vPos * _ui.wrapper.height;
            } );
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.removeEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );

            _ui.arrowIndicator.pageRectFunc = pageRectHandler;
            _ui.arrowIndicator.hasLeftFunc = hasLeft;
            _ui.arrowIndicator.hasRightFunc = hasRight;
            _ui.arrowIndicator.isAnimatingFunc = isAnimatingFunc;

            new ResizeHelper( this , resizeHandler );

            progress = new ProgressBar();
            progress.indeterminate = true;
            progress.labelPlacement = ProgressBarLabelPlacement.CENTER;

            _ui.wrapper.addElement( progress );

            progress.x = ( _ui.width - 150 ) / 2;
            progress.y = ( _ui.height - 4 ) / 2;
        }

        private function get currentForePage() : PageComponent {
            if ( !_pages ) {
                return null;
            }

            return pages[ currentPage ];
        }

        private function get currentPage() : int {
            return _pageHeadHelpers[ _currentDocPos ].headToPage( _currentHead );
        }

        private function get currentRearPage() : PageComponent {
            if ( !_pages || !pages || _pageHeadHelpers[ _currentDocPos ].isSingleHead( _currentHead ) ) {
                return null;
            }

            return pages[ currentPage + 1 ];
        }

        private function easeInOutQuart( t : Number ) : Number {
            // cubic
            // return t < 0.5 ? 4 * t * t * t : 4 * ( t - 1 ) * ( t - 1 ) * ( t - 1 ) + 1;

            return t < 0.5 ? 8 * t * t * t * t : -8 * ( t - 1 ) * ( t - 1 ) * ( t - 1 ) * ( t - 1 ) + 1;
        }

        private function fitWrapperSize( page : PageComponent ) : void {
            if ( page == null || _ui == null || page.content == null ) {
                return;
            }

            var w : int = page.content.width * 2;

            if ( _ui.width / w > _ui.height / page.content.height ) {
                // fit to height
                _baseScale = _ui.height / page.content.height;
            } else {
                // fit to width
                _baseScale = _ui.width / w;
            }

            changeScale();
        }

        private function getCurrentPages() : Vector.<PageComponent> {
            var ret : Vector.<PageComponent> = new Vector.<PageComponent>();

            ret.push( currentForePage );

            if ( currentRearPage ) {
                ret.push( currentRearPage );
            }

            return ret;
        }

        private function hasLeft() : Boolean {
            return isBindingRight ? hasNext() : hasPrev();
        }

        private function hasNext() : Boolean {
            return _currentDocPos + 1 < _infos.length ||
                _pageHeadHelpers[ _currentDocPos ].isValidHead( _currentHead + 1 );
        }

        private function hasPrev() : Boolean {
            return _currentDocPos - 1 >= 0 || _pageHeadHelpers[ _currentDocPos ].isValidHead( _currentHead - 1 );
        }

        private function hasRight() : Boolean {
            return isBindingRight ? hasPrev() : hasNext();
        }

        private function initLoadComplete( page : PageComponent ) : void {
            fitWrapperSize( page );

            //_mouseEventHelper.scroller = _ui.scroller;
            _mouseEventHelper.scroller = _ui.wrapper;
            _mouseEventHelper.arrowIndicator = _ui.arrowIndicator;
            _mouseEventHelper.init( this );

            if ( progress ) {
                _ui.wrapper.removeElement( progress );
                progress = null;
            }
        }

        private function set isAnimating( value : Boolean ) : * {
            _isAnimating = value;

            if ( _isAnimating ) {
                _ui.arrowIndicator.startAnimating();
            } else {
                _ui.arrowIndicator.endAnimating();
            }
        }

        private function isAnimatingFunc() : Boolean {
            return _isAnimating;
        }

        private function loadFullByPage( page : int ) : void {
            addItemToLoadQueue( page );
            addItemToLoadQueue( page + 1 );
            loadNeighborPage();

            if ( !_pageHeadHelpers[ _currentDocPos ].isSingleHead( _pageHeadHelpers[ _currentDocPos ].pageToHead( page ) ) ) {
                addPage( pages[ page ] , true , function( _p_ : PageComponent ) : void {
                    addPage( pages[ page + 1 ] , false , initLoadComplete );
                } );
            } else {
                addPage( pages[ page ] , !isBindingRight , initLoadComplete );
            }
        }

        private function loadHelepr( position : int ) : void {
            if ( position < _dtos.length ) {
                DocumentService.getInfo( _dtos[ position ].id , function( json : Object ) : void {
                    _infos[ position ] = json;

                    DocumentService.getSinglePageInfo( _dtos[ position ].id ,
                                                       function( singlePages : ArrayCollection ) : void {
                        _pageHeadHelpers[ position ] =
                            new PageHeadHelper( singlePages.toArray() , _infos[ position ].pages );
                        _pages[ position ] = new Vector.<PageComponent>( _infos[ position ].pages );

                        DocumentService.getImageInfo( _dtos[ position ].id , function( json : Object ) : void {
                            _imageInfo = json;

                            loadHelepr( position + 1 );
                        } );
                    } );
                } );
            } else {
                currentHead = 0;
                _currentDocPos = 0;
                _zoomExponent = 0;

                _loadingCount = 0;

                loadFullByPage( 0 );
            }
        }

        /**
         * Ignore neighbor document, currently
         */
        private function loadNeighborPage() : void {
            var page : int = currentPage;

            for ( var index : int = 0 ; index < _infos[ _currentDocPos ].pages ; index++ ) {
                if ( index < page - 4 || index > page + 9 ) {
                    delete pages[ index ];
                    pages[ index ] = null;
                }
            }

            addItemToLoadQueue( page + 2 );
            addItemToLoadQueue( page + 3 );
            addItemToLoadQueue( page - 1 );
            addItemToLoadQueue( page - 2 );
            addItemToLoadQueue( page + 4 );
            addItemToLoadQueue( page + 5 );
            addItemToLoadQueue( page - 3 );
            addItemToLoadQueue( page - 4 );
            addItemToLoadQueue( page + 6 );
            addItemToLoadQueue( page + 7 );
            addItemToLoadQueue( page + 8 );
            addItemToLoadQueue( page + 9 );

            loadQueueHeadPage();
        }

        private function loadPage( index : int , next : Function = null ) : void {
            var page : int = currentPage;

            if ( index >= 0 && index < _infos[ _currentDocPos ].pages && !( index < page - 4 || index > page + 9 ) &&
                pages[ index ] && !pages[ index ].loading && !pages[ index ].loaded ) {
                _loadingCount++;

                var pc : PageComponent = pages[ index ];

                pc.loadAll( docId , ratio , TEXTURE_LEVEL , calcMainPageSize() , _contextMenuHelper ,
                            _mouseEventHelper.isMenuVisbleFunc , changePageHandler , function() : void {
                    _loadingCount--;

                    if ( next != null ) {
                        next( pc );
                    }
                } );
            } else {
                if ( next != null ) {
                    next( null );
                }
            }
        }

        private function loadQueueHeadPage() : void {
            if ( _loadingCount > 0 ) {
                return;
            }

            if ( _loadQueue.length == 0 ) {
                return;
            }

            var page : int = _loadQueue.shift();

            loadPage( page , function( pc : PageComponent ) : void {
                loadQueueHeadPage();
            } );
        }

        private function moveLeft() : void {
            isBindingRight ? moveToNextPage() : moveToPrevPage();
        }

        private function moveRight() : void {
            isBindingRight ? moveToPrevPage() : moveToNextPage();
        }

        private function moveToNextPage() : void {
            changeHead( _currentHead + 1 );
        }

        private function moveToPrevPage() : void {
            changeHead( _currentHead - 1 );
        }

        private function myKeyUpHandler( e : KeyboardEvent ) : void {
            if ( !( e.target is IIMESupport ) ) {
                if ( e.keyCode == 'J'.charCodeAt( 0 ) ) {
                    moveLeft();
                } else if ( e.keyCode == 'K'.charCodeAt( 0 ) ) {
                    moveRight();
                }
            }
        }

        private function nullSafeGetBitmapData( page : PageComponent ) : BitmapData {
            if ( page ) {
                return page.bitmapData;
            } else {
                // may cause error when current == null
                var current : PageComponent = currentForePage;
                return new BitmapData( current.width , current.height );
            }
        }

        private function pageRectHandler() : Rectangle {
            return new Rectangle( _ui.scroller.x , _ui.scroller.y ,
                                  Math.min( _ui.arrowIndicator.width - _ui.scroller.x ,
                                            _ui.wrapper.contentWidth * _ui.wrapper.scaleX ) ,
                                  Math.min( _ui.arrowIndicator.height - _ui.scroller.y ,
                                            _ui.wrapper.contentHeight * _ui.wrapper.scaleY ) );
        }

        private function resizeHandler() : void {
            if ( !visible ) {
                return;
            }

            if ( !_ui ) {
                return;
            }

            if ( currentForePage ) {
                fitWrapperSize( currentForePage );
            }
        }

        /**
         * Perform in region (0,0)-(page.width*2,page.height)
         */
        private function startFlip( front : PageComponent , back : PageComponent , isForward : Boolean ,
                                    beginFlip : Function , endFlip : Function , deltaX : Number = 0 ) : void {
            var N_STEP : int = 12;

            var w : Number = currentForePage.width;
            var h : Number = currentForePage.height;

            var render : Shape = new Shape();
            var wrapper : UIComponent = new UIComponent();
            wrapper.x = w;
            wrapper.addChild( render );
            _ui.wrapper.addElement( wrapper );

            var initX : Number = _ui.scroller.x;

            var l : PageComponent = isBindingRight ? front : back;
            var r : PageComponent = isBindingRight ? back : front;

            var step : int = 0;
            systemManager.addEventListener( Event.ENTER_FRAME , function( e : Event ) : void {
                if ( step < N_STEP ) {
                    _ui.scroller.viewport.clipAndEnableScrolling = false;

                    var sign : int = isForward == isBindingRight ? 1 : -1;

                    render.graphics.clear();
                    var t : Number = easeInOutQuart( step / ( N_STEP - 1 ) );
                    var point : Point =
                        calcBezierPoint( new Point( -w * sign , h ) , new Point( w * sign , h ) , new Point( 0 , 0 ) ,
                                                    t );
                    var o : Object = PageFlip.computeFlip( point , new Point( 1 , 1 ) , w , h , true , 1 );

                    PageFlip.drawBitmapSheet( o , render , nullSafeGetBitmapData( l ) , nullSafeGetBitmapData( r ) );

                    _ui.scroller.x = initX + t * deltaX;

                    if ( step == 0 ) {
                        beginFlip();
                    }

                    step++;
                } else {
                    systemManager.removeEventListener( Event.ENTER_FRAME , arguments.callee );

                    _ui.wrapper.removeElement( wrapper );

                    //_ui.scroller.x = calcCenterX( _ui.wrapper.contentWidth * _ui.wrapper.scaleX );

                    endFlip();

                    _ui.scroller.viewport.clipAndEnableScrolling = true;
                }
            } );
        }

        private function zoom() : void {
            _zoomExponent = _zoomExponent == 4 ? 0 : Math.min( _zoomExponent + 2 , 4 );

            changeScale();
        }
    }
}
