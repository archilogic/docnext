package jp.archilogic.docnext.ui {
    import flash.events.MouseEvent;
    import mx.controls.Image;

    public class ImageButton extends Image {
        public function ImageButton() {
            super();

            addEventListener( MouseEvent.MOUSE_OVER , mouseOverHandler );
            addEventListener( MouseEvent.MOUSE_OUT , mouseOutHandler );
            addEventListener( MouseEvent.MOUSE_DOWN , mouseDownHandler );
            addEventListener( MouseEvent.MOUSE_UP , mouseUpHandler );
        }

        private var _sourceNormal : Object;
        private var _sourceOver : Object;
        private var _sourceDown : Object;

        override public function set enabled( value : Boolean ) : void {
            super.enabled = value;

            if ( value ) {
                alpha = 1;
            } else {
                alpha = 0.5;
                source = _sourceNormal;
            }
        }

        public function set sourceDown( value : Object ) : void {
            _sourceDown = value;
        }

        public function set sourceNormal( value : Object ) : void {
            _sourceNormal = value;
            source = value;
        }

        public function set sourceOver( value : Object ) : void {
            _sourceOver = value;
        }

        private function mouseDownHandler( e : MouseEvent ) : void {
            if ( _sourceDown && enabled ) {
                source = _sourceDown;
            }
        }

        private function mouseOutHandler( e : MouseEvent ) : void {
            if ( _sourceNormal && enabled ) {
                source = _sourceNormal;
            }
        }

        private function mouseOverHandler( e : MouseEvent ) : void {
            if ( _sourceOver && enabled ) {
                source = _sourceOver;
            }
        }

        private function mouseUpHandler( e : MouseEvent ) : void {
            if ( _sourceOver && enabled ) {
                source = _sourceOver;
            }
        }
    }
}