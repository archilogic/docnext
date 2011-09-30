package jp.archilogic.docnext.service {
    import jp.archilogic.Service;
    import jp.archilogic.ServiceUtil;
	import mx.controls.Alert;
    public class DocumentService {
        private static var service : Service = new Service( 'documentService' );

        public static function findById( id : Number , result : Function , fault : Function ) : void {
            ServiceUtil.callHelper( service.findById( id ) , result , fault );
        }

        public static function getAnnotation( id : Number , page : int , result : Function ) : void {
            ServiceUtil.callHelper( service.getAnnotation( id , page ) , result );
        }

        public static function getImageText( id : Number , page : int , result : Function ) : void {
            ServiceUtil.callHelper( service.getImageText( id , page ) , result );
        }

        public static function getImageInfo( id : Number , result : Function ) : void {
            ServiceUtil.callHelper( service.getImageInfo( id ) , result );
        }

        public static function getInfo( id : Number , result : Function ) : void {
            ServiceUtil.callHelper( service.getInfo( id ) , result );
        }

        /*public static function getPage( id : Number , page : int , result : Function ) : void {
            ServiceUtil.callHelper( service.getPage( id , page ) , result );
        }*/

        public static function getPageTexture( id : Number , page : int , level : int , px : int , py : int , result : Function ) : void {
            ServiceUtil.callHelper( service.getPageTexture( id , page , level , px , py ) , result );
        }

        public static function getThumb( id : Number , page : int , result : Function ) : void {
             ServiceUtil.callHelper( service.getThumb( id , page ) , result ); 
        }
        
        public static function getRegions( id : Number , page : int , result : Function ) : void {
            ServiceUtil.callHelper( service.getRegions( id , page ) , result );
        }

        public static function getSinglePageInfo( id : Number , result : Function ) : void {
            ServiceUtil.callHelper( service.getSinglePageInfo( id ) , result );
        }
        
    }
}
