package jp.archilogic.docnext.android.util;

import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import android.content.res.Resources;

public class ImageLevelUtil {
    public static int getMaxLevel( final int minLevel , final int imageMaxLevel , final int imageMaxNumberOfLevel ) {
        return minLevel + getNumberOfLevel( minLevel , imageMaxLevel , imageMaxNumberOfLevel ) - 1;
    }

    public static int getMinLevel( final Resources res , final int imageMaxLevel ) {
        return Math.min( Math.max( ( int ) Math.ceil( Math.log( 1.0 * getShortSide( res ) / RemoteProvider.TEXTURE_SIZE ) / Math.log( 2 ) ) , 0 ) ,
                imageMaxLevel );
    }

    private static int getNumberOfLevel( final int minLevel , final int imageMaxLevel , final int imageMaxNumberOfLevel ) {
        final int limit = imageMaxNumberOfLevel > 0 ? imageMaxNumberOfLevel : 3;

        return Math.min( imageMaxLevel - minLevel + 1 , limit );
    }

    private static int getShortSide( final Resources res ) {
        return Math.min( res.getDisplayMetrics().widthPixels , res.getDisplayMetrics().heightPixels );
    }
}
