package jp.archilogic.docnext.util {
    import flash.utils.ByteArray;
    import mx.utils.SHA256;

    public class HashUtil {
        public static function hash( string : String ) : String {
            var byteArray : ByteArray = new ByteArray();
            byteArray.writeUTFBytes( string );
            byteArray.position = 0;
            return SHA256.computeDigest( byteArray );
        }
    }
}