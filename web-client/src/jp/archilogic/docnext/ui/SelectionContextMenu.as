package jp.archilogic.docnext.ui {
    import flash.events.MouseEvent;
    import flash.system.System;
    import mx.containers.Box;
    import mx.events.FlexEvent;

    public class SelectionContextMenu extends Box {
        public function SelectionContextMenu( page : PageComponent , dismissFunc : Function ) {
            _page = page;
            _dismissFunc = dismissFunc;

            _ui = new SelectionContextMenuUI();
            _ui.addEventListener( FlexEvent.CREATION_COMPLETE , creationCompleteHandler );
            addChild( _ui );
        }

        private var _ui : SelectionContextMenuUI;

        private var _page : PageComponent;
        private var _dismissFunc : Function;

        private function changeToHighlightButtonClickHandler( e : MouseEvent ) : void {
            e.stopPropagation();

            _page.changeSelectionToHighlight();

            _dismissFunc();
        }

        private function copyButtonClickHandler( e : MouseEvent ) : void {
            e.stopPropagation();

            System.setClipboard( _page.selectedText );

            _dismissFunc();
        }

        private function creationCompleteHandler( e : FlexEvent ) : void {
            _ui.copyButton.addEventListener( MouseEvent.CLICK , copyButtonClickHandler );
            _ui.changeToHighlightButton.addEventListener( MouseEvent.CLICK , changeToHighlightButtonClickHandler );
            _ui.addEventListener( MouseEvent.MOUSE_DOWN , mouseDownHandler );
        }

        private function mouseDownHandler( e : MouseEvent ) : void {
            e.stopPropagation();
        }
    }
}