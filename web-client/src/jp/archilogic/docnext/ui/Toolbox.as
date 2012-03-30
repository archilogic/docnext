package jp.archilogic.docnext.ui {
    import flash.events.MouseEvent;
    import flash.net.SharedObject;
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import mx.events.FlexEvent;
    import jp.archilogic.docnext.helper.PageHeadHelper;
    import jp.archilogic.docnext.util.PrintWindow;

    public class Toolbox extends Canvas {
        public function Toolbox() {
            super();

            _ui = new ToolboxUI();
            _ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            addChild( _ui );
        }

        public var view : Viewer;

        private var _changeMenuVisibilityHandler : Function;
        private var _documentComponent : DocumentComponent;
        private var _selectingHandler : Function;
        private var _showTOCHandler : Function;
        private var _showThumbnailsHandler : Function;
        private var _ui : ToolboxUI;
        private var _zoomInHandler : Function;
        private var _zoomOutHandler : Function;

        public function set changeMenuVisiblityHandler( value : Function ) : * {
            _changeMenuVisibilityHandler = value;
        }

        public function set documentComponent( value : DocumentComponent ) : void {
            this._documentComponent = value;
        }

        public function set selectingHandler( value : Function ) : * {
            _selectingHandler = value;
        }

        public function setPage( current : int , total : int ) : void {
            // change to 1-origin
            _ui.pageLabel.text = ( current + 1 ) + '/' + total;
        }

        public function set showTOCHandler( value : Function ) : void {
            _showTOCHandler = value;
        }

        public function set showThumbnailsHandler( value : Function ) : void {
            _showThumbnailsHandler = value;
        }

        public function set zoomInHandler( value : Function ) : * {
            _zoomInHandler = value;
        }

        public function set zoomOutHandler( value : Function ) : * {
            _zoomOutHandler = value;
        }

        private function alignComponentSize() : void {
            var maxWidth : Number =
                Math.max( _ui.tocButton.width , _ui.thumbnailButton.width , _ui.bookmarkButton.width );

            _ui.tocButton.width = maxWidth;
            _ui.thumbnailButton.width = maxWidth;
            _ui.bookmarkButton.width = maxWidth;
        }

        private function beginSelectionButtonClickHandler( e : MouseEvent ) : void {
            _selectingHandler( true );
            _changeMenuVisibilityHandler( false );
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.removeEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );

            _ui.tocButton.addEventListener( MouseEvent.CLICK , tocShowHandler );
            _ui.thumbnailButton.addEventListener( MouseEvent.CLICK , thumbnailsShowHandler );

            function showBookmark( e : MouseEvent ) : void {
                view.bookmark.refreshButton();
                view.bookmark.visible = true;
            }
            _ui.bookmarkButton.addEventListener( MouseEvent.CLICK , showBookmark );
            //_ui.searchButton.addEventListener( MouseEvent.CLICK , temp );
            //_ui.beginSelectionButton.addEventListener( MouseEvent.CLICK , beginSelectionButtonClickHandler );

            _ui.printButton.addEventListener( MouseEvent.CLICK , printHandler );
            alignComponentSize();
        }

        private function printHandler( e : MouseEvent ) : void {
            if ( _documentComponent == null ) {
                return;
            }
            PrintWindow.show( _documentComponent );
        }

        private function temp( e : MouseEvent ) : void {
            Alert.show( 'Under construction' );
        }

        private function thumbnailsShowHandler( e : MouseEvent ) : void {
            _showThumbnailsHandler( true );
        }

        private function tocShowHandler( e : MouseEvent ) : void {
            _showTOCHandler();
        }
    }
}
