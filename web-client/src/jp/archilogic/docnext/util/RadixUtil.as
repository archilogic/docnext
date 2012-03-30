package jp.archilogic.docnext.util {

    public class RadixUtil {
        private static const SEQ : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

        public static function toInt( value : String ) : int {
            var ret : int = 0;

            for ( var i : int = value.length - 1 ; i >= 0 ; i-- ) {
                ret = ret * SEQ.length + SEQ.indexOf( value.charAt( i ) );
            }

            return ret;
        }

        public static function toString( value : int ) : String {
            var ret : String = '';

            while ( value > 0 ) {
                ret += SEQ.charAt( value % SEQ.length );
                value /= SEQ.length;
            }

            return ret;
        }
    }
}
