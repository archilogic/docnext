package jp.archilogic.docnext.helper {
    import mx.core.Container;
    import caurina.transitions.Tweener;
    import jp.archilogic.docnext.ui.HighlightContextMenu;
    import jp.archilogic.docnext.ui.PageComponent;
    import jp.archilogic.docnext.ui.SelectionContextMenu;

    public class ContextMenuHelper {
        public function ContextMenuHelper( holder : Container ) {
            _holder = holder;
        }

        private var _holder : Container;

        private var _selectionContextMenu : SelectionContextMenu;
        private var _highlightContextMenu : HighlightContextMenu;

        public function get isShowingHighlightContextMenu() : Boolean {
            return _highlightContextMenu != null;
        }

        public function get isShowingSelectionContextMenu() : Boolean {
            return _selectionContextMenu != null;
        }

        public function removeHighlightContextMenu() : void {
            Tweener.addTween( _highlightContextMenu , { alpha: 0 , time: 0.5 , onComplete: function() : void {
                        _holder.removeChild( _highlightContextMenu );
                        _highlightContextMenu = null;
                    } } );
        }

        public function removeSelectionContextMenu() : void {
            Tweener.addTween( _selectionContextMenu , { alpha: 0 , time: 0.5 , onComplete: function() : void {
                        _holder.removeChild( _selectionContextMenu );
                        _selectionContextMenu = null;
                    } } );
        }

        public function showHighlightContextMenu( target : OverlayHelper , initComment : String ,
                                                  dismiss : Function ) : void {
            if ( _highlightContextMenu ) {
                Tweener.removeTweens( _highlightContextMenu );
                _holder.removeChild( _highlightContextMenu );
            }

            _highlightContextMenu = new HighlightContextMenu( target , initComment , dismiss );

            _highlightContextMenu.alpha = 0;
            _holder.addChild( _highlightContextMenu );

            Tweener.addTween( _highlightContextMenu , { alpha: 1 , time: 0.5 } );
        }

        public function showSelectionContextMenu( target : PageComponent , dismiss : Function ) : void {
            if ( _selectionContextMenu ) {
                Tweener.removeTweens( _selectionContextMenu );
                _holder.removeChild( _selectionContextMenu );
            }

            _selectionContextMenu = new SelectionContextMenu( target , dismiss );

            _selectionContextMenu.alpha = 0;
            _holder.addChild( _selectionContextMenu );

            Tweener.addTween( _selectionContextMenu , { alpha: 1 , time: 0.5 } );
        }
    }
}