package jp.archilogic.docnext.helper {
    import flash.events.EventDispatcher;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import mx.events.ResizeEvent;

    public class ResizeHelper {
        public function ResizeHelper( target : EventDispatcher , handler : Function ) {
            _resizeTimeoutExists = false;

            _handler = handler;

            target.addEventListener( ResizeEvent.RESIZE , resizeHanlder );
        }

        /* public function removeResizeHelper() :void
        {
            _target.removeEventListener( ResizeEvent.RESIZE , resizeHanlder )
        }
        public function addResizeHelper() : void
        {
            _target.addEventListener( ResizeEvent.RESIZE , resizeHanlder );
        } */

        private var _handler : Function;
        private var _resizeTimeoutExists : Boolean;
        private var _resizeTimeoutId : uint;
        private var _target : EventDispatcher;

        private function resizeHanlder( e : ResizeEvent ) : void {
            if ( _resizeTimeoutExists ) {
                clearTimeout( _resizeTimeoutId );
            }

            _resizeTimeoutExists = true;
            _resizeTimeoutId = setTimeout( function() : void {
                _handler();
            } , 100 );
        }
    }
}
