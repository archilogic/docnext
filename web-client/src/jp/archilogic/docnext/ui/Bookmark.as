package jp.archilogic.docnext.ui
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.net.SharedObject;
    
    import jp.archilogic.docnext.resource.Resource;
    import jp.archilogic.docnext.util.DocumentLoadUtil;
    
    import mx.containers.Canvas;
    import mx.controls.Alert;
    import mx.controls.Image;

    public class Bookmark extends Canvas
    {
        
        public function Bookmark()
        {
            super();

            ui = new BookmarkUI();
            addChild( ui );
            
            var so : SharedObject = SharedObject.getLocal( "Bookmark" );
            if ( !so.data.hasOwnProperty( "bookmarks" ) ) {
                so.data.bookmarks = new Array();
            }
            for ( var i : int; i < so.data.bookmarks.length; i++ ) {
                ui.list.addItem( { page: so.data.bookmarks[ i ] , thumb:"" , docId:docId } );
            }
            
            function addBookmark( e : MouseEvent ) : void {
                var page : int = view.documentComponent.currentPageByHead;
                var bookmark : Object =  { page: page , docId:docId };
                var contain : Boolean = false;
                
                for (var i : int = 0; i < ui.list.length; i++) {
                    if ( ui.list[ i ].page == bookmark.page ) {
                        contain = true;
                    }
                }
                if ( !contain ) {
                    ui.list.addItem( bookmark );
                    so.data.bookmarks.push( bookmark.page );
                }
                so.flush();
                refresh();
                turnOnBookmarkButton();
            }
            
            function clickStar( e : MouseEvent ) : void {
                var so : SharedObject = SharedObject.getLocal( "Bookmark" );
                var currentPage : int = view.documentComponent.currentPageByHead;
                
                var bk : Array = so.data.bookmarks;
                if ( bk.indexOf( currentPage ) != -1 ) {
                    deleteBookmark( e );
                } else {
                    addBookmark( e );
                }
            }
            
            ui.star.addEventListener( MouseEvent.CLICK , clickStar );
            
            function deleteBookmark( e: MouseEvent ) : void {
                var page : int = view.documentComponent.currentPageByHead;
                for ( var i : int = 0; i < ui.list.length; i++ ) {
                    if ( ui.list[ i ].page == page ) {
                        ui.list.removeItemAt( i );
                        var a : Array = new Array();
                        for ( var j : int = 0; j < ui.list.length; j++ ) {
                            a.push( ui.list[ j ].page );
                        }
                        so.data.bookmarks = a;
                    }
                }
                so.flush();
                refresh();
                turnOffBookmarkButton();
            }
            
            function clickGrid( e : MouseEvent ) : void {
                var head : int = ui.dg.selectedItem[ "page" ];
                view.documentComponent.currentHeadByPage = head;
                view.bookmark.visible = false;
            }
            ui.dg.addEventListener( MouseEvent.CLICK , clickGrid );
        }
        
        private var ui : BookmarkUI;
        public var view : Viewer;
        
        private function turnOnBookmarkButton() : void {
            ui.star.source = Resource.BUTTON_BOOKMARK_ON;
        }
        
        private function turnOffBookmarkButton() : void {
            ui.star.source = Resource.BUTTON_BOOKMARK_OFF;
        }
        
        private function refresh() : void {
            ui.list.refresh();
            refreshButton();
        }
        
        private function docId() : String {
            return view.documentComponent.docId.toString(); 
        }
        
        public function refreshButton() : void {
            var so : SharedObject = SharedObject.getLocal( "Bookmark" );
            var currentPage : int = view.documentComponent.currentPageByHead;
            
            var bk : Array = so.data.bookmarks;
            if ( bk.indexOf( currentPage ) != -1 ) {
                turnOnBookmarkButton();
            } else {
                turnOffBookmarkButton();
            }
        }
        

    }
}