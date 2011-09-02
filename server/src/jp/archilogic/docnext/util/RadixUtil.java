package jp.archilogic.docnext.util;

public class RadixUtil {

    private static final String SEQ = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    public static int toInt( String value ) {
        int ret = 0;

        for ( int i = value.length() - 1 ; i >= 0 ; i-- ) {
            ret = ret * SEQ.length() + SEQ.indexOf( value.charAt( i ) );
        }

        return ret;
    }

    public static String toString( int value ) {
        StringBuilder ret = new StringBuilder();

        while ( value > 0 ) {
            ret.append( SEQ.charAt( value % SEQ.length() ) );
            value /= SEQ.length();
        }

        return ret.toString();
    }
}
