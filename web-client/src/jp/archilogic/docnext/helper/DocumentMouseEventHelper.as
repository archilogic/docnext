package jp.archilogic.docnext.helper {
    import flash.events.Event;
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    
    import jp.archilogic.docnext.ui.DocumentComponentArrowIndicator;
    import jp.archilogic.docnext.ui.PageComponent;
    
    import mx.core.Container;
    import mx.core.UIComponent;
    
    import spark.components.Group;
    import spark.components.Scroller;

    public class DocumentMouseEventHelper {
        private static const CLICK_THRESHOLD : Number = 5;

        public function DocumentMouseEventHelper() {
            _selecting = false;
        }

        private var _scroller : Group;
        private var _contextMenuHelper : ContextMenuHelper;

        // menu var
        private var _isMenuVisibleFunc : Function;
        private var _changeMenuVisiblityFunc : Function;
        // change page var
        private var _arrowIndicator : DocumentComponentArrowIndicator;
        private var _changePageFunc : Function;
        // selecting var
        private var _selecting : Boolean;
        private var _selectingTarget : PageComponent;
        private var _selectingEdge : int;
        private var _hasSelection : Boolean;

        private var _currentPagesFunc : Function;

        private var _isClick : Boolean;
        private var _mouseDownPoint : Point;
        private var _mouseDownScrollPos : Point;

        public function set arrowIndicator( value : DocumentComponentArrowIndicator ) : * {
            _arrowIndicator = value;
        }
		public function get arrowIndicator( ) : DocumentComponentArrowIndicator
		{
			return _arrowIndicator;
		}
        public function set changeMenuVisiblityFunc( value : Function ) : * {
            _changeMenuVisiblityFunc = value;
        }

        public function set changePageFunc( value : Function ) : * {
            _changePageFunc = value;
        }

        public function set contextMenuHelper( value : ContextMenuHelper ) : * {
            _contextMenuHelper = value;
        }

        public function set currentPagesFunc( value : Function ) : * {
            _currentPagesFunc = value;
        }

        public function init( target : IEventDispatcher ) : void {
            target.addEventListener( MouseEvent.CLICK , clickHandler );
            target.addEventListener( MouseEvent.MOUSE_DOWN , mouseDownHandler );
            target.addEventListener( MouseEvent.MOUSE_MOVE , mouseMoveHandler );
            target.addEventListener( MouseEvent.MOUSE_UP , mouseUpHandler );
        }

        public function get isMenuVisbleFunc() : Function {
            return _isMenuVisibleFunc;
        }

        public function set isMenuVisibleFunc( value : Function ) : * {
            _isMenuVisibleFunc = value;
        }

        public function set scroller( value : Group ) : * {
            _scroller = value;
        }

        public function set selecting( value : Boolean ) : * {
            _selecting = value;
        }

        private function clickHandler( e : MouseEvent ) : void {
            if ( !_isClick ) {
                return;
            }
            _isClick = false;

            if ( _isMenuVisibleFunc() ) {
                _changeMenuVisiblityFunc( false );
            } else if ( _selecting ) {
                _selecting = false;
                _changeMenuVisiblityFunc( true );
            } else if ( _arrowIndicator.isShowingIndicator ) {
                _changePageFunc( _arrowIndicator.isShowingLeftIndicator ? 1 : -1 );
            } else {
                _changeMenuVisiblityFunc( true );
            }
        }

        private function dismissSelectionContextMenuFunc() : void {
            _selecting = false;
            _selectingTarget.initSelection();

            _contextMenuHelper.removeSelectionContextMenu();
        }

        private function hypot( x : Point , y : Point ) : Number {
            return Math.sqrt( Math.pow( x.x - y.x , 2 ) + Math.pow( x.y - y.y , 2 ) );
        }

        private function mouseDownHandler( e : MouseEvent ) : void {
            _isClick = true;
            _mouseDownPoint = new Point( e.stageX , e.stageY );

            if ( _contextMenuHelper.isShowingSelectionContextMenu ) {
                _contextMenuHelper.removeSelectionContextMenu();
            }

            if ( _contextMenuHelper.isShowingHighlightContextMenu ) {
                _contextMenuHelper.removeHighlightContextMenu();
            }

            for each ( var page : PageComponent in _currentPagesFunc() ) {
                if( page == null) page = new PageComponent(page.page);
                if( page !=null) page.initSelection();
                page.clearEmphasize();
            }

            if ( !_isMenuVisibleFunc() ) {
                if ( _selecting ) {
                    _selectingTarget = travPage( e );
                    _hasSelection = false;

                    if ( _selectingTarget ) {
                        _selectingEdge =
                            _selectingTarget.getNearTextPos( new Point( _selectingTarget.mouseX ,
                                                                        _selectingTarget.mouseY ) );

                        if ( _selectingEdge != -1 ) {
                            _selectingTarget.initSelection();
                        }
                    }
                } else {
                    _mouseDownScrollPos =
                        new Point( _scroller.horizontalScrollPosition , _scroller.verticalScrollPosition );
                }
            }
        }

        private function mouseMoveHandler( e : MouseEvent ) : void {
            if ( _isClick ) {
                _isClick = hypot( _mouseDownPoint , new Point( e.stageX , e.stageY ) ) < CLICK_THRESHOLD;
            }

            if ( !_isMenuVisibleFunc() ) {
                if ( !e.buttonDown ) {
                    if ( !_selecting ) {
                        _arrowIndicator.mouseMove();
                    }
                } else {
                    if ( _selecting ) {
                        if ( _selectingTarget ) {
                            var index : int =
                                _selectingTarget.getNearTextPos( new Point( _selectingTarget.mouseX ,
                                                                            _selectingTarget.mouseY ) );
                            _selectingTarget.showSelection( Math.min( _selectingEdge , index ) ,
                                                                      Math.max( _selectingEdge , index ) );

                            _hasSelection = true;
                        }
                    } else {
                        _scroller.horizontalScrollPosition = _mouseDownScrollPos.x - e.stageX + _mouseDownPoint.x;
                        _scroller.verticalScrollPosition = _mouseDownScrollPos.y - e.stageY + _mouseDownPoint.y;
                    }
                }
            }
        }

        private function mouseUpHandler( e : MouseEvent ) : void {
            if ( _selecting && _hasSelection ) {
                _contextMenuHelper.showSelectionContextMenu( _selectingTarget , dismissSelectionContextMenuFunc );
            }
        }

        private function travPage( e : Event ) : PageComponent {
            if ( e.target is UIComponent ) {
                var target : UIComponent = UIComponent( e.target );

                while ( target.parent ) {
                    if ( target is PageComponent ) {
                        return PageComponent( target );
                    }

                    if ( target.parent is UIComponent ) {
                        target = UIComponent( target.parent );
                    } else {
                        return null;
                    }
                }
            }

            return null;
        }
    }
}