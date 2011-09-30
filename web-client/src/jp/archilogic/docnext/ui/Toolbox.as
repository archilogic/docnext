package jp.archilogic.docnext.ui {
    import flash.events.MouseEvent;
    
    import jp.archilogic.docnext.helper.PageHeadHelper;
    import jp.archilogic.docnext.util.PrintWindow;
    
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import mx.events.FlexEvent;

    public class Toolbox extends Canvas {
        public function Toolbox() {
            super();

            _ui = new ToolboxUI();
            _ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            addChild( _ui );
        }
		
		private var _documentComponent:DocumentComponent;
        private var _ui : ToolboxUI;

        private var _zoomInHandler : Function;
        private var _zoomOutHandler : Function;
        private var _changeMenuVisibilityHandler : Function;
        private var _selectingHandler : Function;
        
        private var _showThumbnailsHandler : Function;
		
		public function set documentComponent( value : DocumentComponent ) : void {
			this._documentComponent = value;
		}
        public function set showThumbnailsHandler( value : Function) : void 
        {
        	_showThumbnailsHandler = value;
        }
		
        public function set changeMenuVisiblityHandler( value : Function ) : * {
            _changeMenuVisibilityHandler = value;
        }

        public function set selectingHandler( value : Function ) : * {
            _selectingHandler = value;
        }

        public function setPage( current : int , total : int ) : void {
            // change to 1-origin
            _ui.pageLabel.text = ( current + 1 ) + '/' + total;
        }

        public function set zoomInHandler( value : Function ) : * {
            _zoomInHandler = value;
        }

        public function set zoomOutHandler( value : Function ) : * {
            _zoomOutHandler = value;
        }
        

        private function alignComponentSize() : void {
            var maxWidth : Number =
                Math.max( _ui.textButton.width , _ui.tocButton.width , _ui.thumbnailButton.width ,
                          _ui.bookmarkButton.width , _ui.searchButton.width );

            _ui.textButton.width = maxWidth;
            _ui.tocButton.width = maxWidth;
            _ui.thumbnailButton.width = maxWidth;
            _ui.bookmarkButton.width = maxWidth;
            _ui.searchButton.width = maxWidth;
        }

        private function beginSelectionButtonClickHandler( e : MouseEvent ) : void {
            _selectingHandler( true );
            _changeMenuVisibilityHandler( false );
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.removeEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );

            _ui.textButton.addEventListener( MouseEvent.CLICK , temp );
            _ui.tocButton.addEventListener( MouseEvent.CLICK , tocShowHandler );
	        _ui.thumbnailButton.addEventListener( MouseEvent.CLICK , thumbnailsShowHandler );
            _ui.bookmarkButton.addEventListener( MouseEvent.CLICK , bookmarkShowHandler );
            _ui.searchButton.addEventListener( MouseEvent.CLICK , temp );
            _ui.beginSelectionButton.addEventListener( MouseEvent.CLICK , beginSelectionButtonClickHandler );

            _ui.zoomInButton.addEventListener( MouseEvent.CLICK , zoomInButtonClickHandler );
            _ui.zoomOutButton.addEventListener( MouseEvent.CLICK , zoomOutButtonClickHandler );

			_ui.printButton.addEventListener(MouseEvent.CLICK, printHandler);
            alignComponentSize();
        }

        private function temp( e : MouseEvent ) : void {
            Alert.show( 'Under construction' );
        }
        private function thumbnailsShowHandler(e : MouseEvent ) :void
        {
        	 _showThumbnailsHandler(true);
        }
		private function bookmarkShowHandler( e : MouseEvent) : void
		{
			Alert.show('Under construction');
		}
		private function tocShowHandler (e :MouseEvent ) :void
		{
			Alert.show("Under construction");
		}
        private function zoomInButtonClickHandler( e : MouseEvent ) : void {
            _zoomInHandler();
        }

        private function zoomOutButtonClickHandler( e : MouseEvent ) : void {
            _zoomOutHandler();
        }
		
		private function printHandler( e : MouseEvent ) : void {
			if(_documentComponent == null) {
				return;
			}
			var docId : int = _documentComponent.docId;
			var pageHeadHelper:PageHeadHelper = _documentComponent.currentPageHeadHelpder;
			var imageInfo:Object = _documentComponent.imageInfo;
//			
			PrintWindow.show(docId, pageHeadHelper, imageInfo);
		}
    }
}
