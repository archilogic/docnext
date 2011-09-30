package jp.archilogic.docnext.controller {
    import __AS3__.vec.Vector;
    
    import caurina.transitions.Tweener;
    
    import jp.archilogic.Delegate;
    import jp.archilogic.ServiceUtil;
    import jp.archilogic.docnext.dto.DocumentResDto;
    import jp.archilogic.docnext.service.DocumentService;
    
    import mx.controls.Alert;
    import mx.rpc.Fault;

    public class ViewerController extends Delegate {
        public var view : Viewer;

        override protected function creationComplete() : void {
            view.toolbox.zoomInHandler = zoomInHandler;
            view.toolbox.zoomOutHandler = zoomOutHandler;
			view.toolbox.documentComponent = view.documentComponent;
            view.documentComponent.setPageHandler = setPageHandler;
            view.documentComponent.isMenuVisibleHandler = isMenuVisibleHandler;
            view.documentComponent.changeMenuVisiblityHandler = changeMenuVisiblityHandler;
            view.toolbox.changeMenuVisiblityHandler = changeMenuVisiblityHandler;
            view.toolbox.selectingHandler = selectingHandler;
			view.toolbox.showThumbnailsHandler = showThumbnailsHandler;
			view.thumbDockComponent.changeThumbDockVisiblityHandler = showThumbnailsHandler;
			view.thumbDockComponent.documentComponent = view.documentComponent;
			
			/* view.thumbDockComponent.changeDocumentVisiblityHandler = changeDocumentVisiblityHandler; */
			
            var ids : String = view.parameters[ 'id' ];

            findDocumentHelper( ids.split( ',' ) , 0 , new Vector.<DocumentResDto> );
        }
        
		 private function showThumbnailsHandler( value : Boolean = true) : void 
		 {
		 	if(value)
		 	{
		 		var currentHead : int  = view.documentComponent.getCurrentHead();
				/* changeDocumentVisiblityHandler(false, 0.3); */
				/* view.documentComponent.alpha = 0.4; */
				view.thumbDockComponent.setBackground(view.documentComponent.background);
                view.thumbDockComponent.flow = view.documentComponent.flow;
				view.documentComponent.removeEvents();
				view.documentComponent.visible = false;
				changeMenuVisiblityHandler(false);
				view.thumbDockComponent.visible = true;
				view.thumbDockComponent.addEvents();
				view.thumbDockComponent.showUp();
		 	}
		 	else /*  documentComponent when thumbnails show off,*/
		 	{
		 		/* view.thumbDockComponent.removeEvents(); */
		 		view.thumbDockComponent.showOff();
		 		view.documentComponent.addEvents();
		 		view.thumbDockComponent.visible = false;
		 		/* view.documentComponent.alpha = 1; */
		 		view.documentComponent.visible = true;
		 		view.documentComponent.setCurrentHead( view.thumbDockComponent.getSelectPage() );
		 	}
		}
		/* private function changeDocumentVisiblityHandler ( value : Boolean , alpha : int = 0 ) : void 
		{
			if(value)
			{
				view.documentComponent.addEvents();
			}
			else
			{
				view.documentComponent.removeEvents();
				if(alpha !=0) 
				{
					view.documentComponent.visible = true;
					view.documentComponent.alpha = alpha;
				}
				else
				{
					view.documentComponent.visible = false;
				}
			}
			
		}  */
        private function changeMenuVisiblityHandler( value : Boolean ) : void {
            if ( value ) {
                view.toolbox.alpha = 0;
                view.toolbox.visible = true;
            }

            Tweener.addTween( view.toolbox , { alpha: value ? 1 : 0 , time: 0.5 , onComplete: function() : void {
                        if ( !value ) {
                            view.toolbox.visible = false;
                            view.toolbox.alpha = 0;
                        }
                    } } );
        }
		
        /**
         * Only check existance currently
         * TODO set title?
         */
        private function findDocumentHelper( 	ids : Array /* of Number or String */ , 
        										position : int ,
                                             	dtos : Vector.<DocumentResDto> ) : void {
            if ( position < ids.length ) {
                DocumentService.findById( ids[ position ] , function( dto : DocumentResDto ) : void {
                    dtos.push( dto );

                    findDocumentHelper( ids , position + 1 , dtos );
                } , function( fault : Fault ) : void {
                    if ( fault.faultCode == 'NotFound' ) {
                        Alert.show( '対象のドキュメントは存在しません' );
                    } else if ( fault.faultCode == 'PrivateDocument' ) {
                        Alert.show( '対象のドキュメントは非公開です' );
                    } else {
                        ServiceUtil.defaultFaultHandler( fault );
                    }
                } );
            } else {
                view.documentComponent.load( dtos );
                /* view.thumbDockComponent.load(dtos); */
            }
        }

        private function isMenuVisibleHandler() : Boolean {
            return view.toolbox.visible;
        }

        private function selectingHandler( value : Boolean ) : void {
            view.documentComponent.selecting = value;
        }

        private function setPageHandler( current : int , total : int ) : void {
            view.toolbox.setPage( current , total );
        }

        private function zoomInHandler() : void {
            view.documentComponent.zoomIn();
        }

        private function zoomOutHandler() : void {
            view.documentComponent.zoomOut();
        }
    }
}