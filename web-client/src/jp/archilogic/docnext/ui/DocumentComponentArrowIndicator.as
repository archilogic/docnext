package jp.archilogic.docnext.ui {
    import flash.display.StageDisplayState;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import mx.containers.Canvas;
    import mx.controls.Image;
    import jp.archilogic.docnext.resource.Resource;

    public class DocumentComponentArrowIndicator extends Canvas {
        private static const ARROW_MODE_RIGHT : int = 1;
        private static const ARROW_MODE_LEFT : int = 0;
        private static const ARROW_MODE_UNDEFINED : int = -1;
        private static const ARROW_HORIZONTAL_SIZE : Object = { width: 76 , height: 87 };
        private static const ARROW_PADDING : Number = 10;
        private static const ARROW_THREASHOLD : Number = 100;

        public function DocumentComponentArrowIndicator() {
            _arrowMode = ARROW_MODE_UNDEFINED;
        }

        private var _pageRectFunc : Function;
        private var _hasLeftFunc : Function;
        private var _hasRightFunc : Function;
        private var _isAnimatingFunc : Function;

        private var _currentArrow : Image;
        private var _arrowMode : int;

        public function endAnimating() : void {
            mouseMove();
        }

        public function set hasLeftFunc( value : Function ) : void {
            _hasLeftFunc = value;
        }

        public function set hasRightFunc( value : Function ) : void {
            _hasRightFunc = value;
        }

        public function set isAnimatingFunc( value : Function ) : * {
            _isAnimatingFunc = value;
        }

        public function get isShowingIndicator() : Boolean {
            return _arrowMode != ARROW_MODE_UNDEFINED;
        }

        public function get isShowingLeftIndicator() : Boolean {
            return _arrowMode == ARROW_MODE_LEFT;
        }

        public function mouseMove() : void {
            _arrowMode = ARROW_MODE_UNDEFINED;

            if ( _isAnimatingFunc() ) {
                return;
            }

            horizontalMouseMoveHandler( new Point( mouseX , mouseY ) );
        }

        public function set pageRectFunc( value : Function ) : void {
            _pageRectFunc = value;
        }

        public function startAnimating() : void {
            removeArrow();
        }

        private function addArrow() : void {
            if ( !_currentArrow ) {
                _currentArrow = new Image();
                _currentArrow.alpha = 0.6;
                addChild( _currentArrow );
            }
        }

        private function horizontalMouseMoveHandler( point : Point ) : void {
            var threashold : Number = stage.displayState == StageDisplayState.NORMAL ? ARROW_THREASHOLD : width / 4;

            var rect : Rectangle = _pageRectFunc();
            var left : Number = rect.x;
            var right : Number = rect.x + rect.width;

            if ( point.x < left + threashold && _hasLeftFunc() ) {
                addArrow();

                _currentArrow.source = Resource.ICON_ARROW_LEFT;
                _currentArrow.x = left + ARROW_PADDING;
                _currentArrow.y = rect.y + rect.height / 2 - ARROW_HORIZONTAL_SIZE.height / 2;

                _arrowMode = ARROW_MODE_LEFT;
            } else if ( point.x > right - threashold && _hasRightFunc() ) {
                addArrow();

                _currentArrow.source = Resource.ICON_ARROW_RIGHT;
                _currentArrow.x = right - ARROW_HORIZONTAL_SIZE.width - ARROW_PADDING;
                _currentArrow.y = rect.y + rect.height / 2 - ARROW_HORIZONTAL_SIZE.height / 2;

                _arrowMode = ARROW_MODE_RIGHT;
            } else {
                removeArrow();
            }
        }

        private function removeArrow() : void {
            if ( _currentArrow ) {
                removeChild( _currentArrow );
                _currentArrow = null;
            }
        }
    }
}