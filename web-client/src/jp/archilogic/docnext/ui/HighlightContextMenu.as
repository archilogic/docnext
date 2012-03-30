package jp.archilogic.docnext.ui {
    import flash.events.Event;
    import flash.events.MouseEvent;
    import mx.containers.Box;
    import mx.events.FlexEvent;
    import jp.archilogic.docnext.helper.OverlayHelper;

    public class HighlightContextMenu extends Box {
        public function HighlightContextMenu( overlay : OverlayHelper , initComment : String , dismissFunc : Function ) {
            _overlay = overlay;
            _initComment = initComment;
            _dismissFunc = dismissFunc;

            _ui = new HighlightContextMenuUI();
            _ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            addChild( _ui );
        }

        private var _dismissFunc : Function;
        private var _initComment : String;
        private var _overlay : OverlayHelper;
        private var _ui : HighlightContextMenuUI;

        private function blueHighlightButtonClick( e : MouseEvent ) : void {
            e.stopPropagation();

            _overlay.changeHighlightColor( 0x0000ff );
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.removeHighlightButton.addEventListener( MouseEvent.CLICK , removeHighlightButtonClickHandler );
            _ui.redHighlightButton.addEventListener( MouseEvent.CLICK , redHighlightButtonClick );
            _ui.greenHighlightButton.addEventListener( MouseEvent.CLICK , greenHighlightButtonClick );
            _ui.blueHighlightButton.addEventListener( MouseEvent.CLICK , blueHighlightButtonClick );
            _ui.highlightCommentTextInput.addEventListener( Event.CHANGE , highlightCommentTextInputChangeHandler );
            _ui.addEventListener( MouseEvent.MOUSE_DOWN , mouseDownHandler );

            _ui.highlightCommentTextInput.text = _initComment;
        }

        private function greenHighlightButtonClick( e : MouseEvent ) : void {
            e.stopPropagation();

            _overlay.changeHighlightColor( 0x00ff00 );
        }

        private function highlightCommentTextInputChangeHandler( e : Event ) : void {
            _overlay.changeHighlightComment( _ui.highlightCommentTextInput.text );
        }

        private function mouseDownHandler( e : MouseEvent ) : void {
            e.stopPropagation();
        }

        private function redHighlightButtonClick( e : MouseEvent ) : void {
            e.stopPropagation();

            _overlay.changeHighlightColor( 0xff0000 );
        }

        private function removeHighlightButtonClickHandler( e : MouseEvent ) : void {
            e.stopPropagation();

            _overlay.removeHighlight();

            _dismissFunc();
        }
    }
}
