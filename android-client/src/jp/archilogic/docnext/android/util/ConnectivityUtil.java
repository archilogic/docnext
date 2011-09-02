package jp.archilogic.docnext.android.util;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

public class ConnectivityUtil {
    public static boolean isNetworkConnected( final Context appContext ) {
        final ConnectivityManager manager = ( ConnectivityManager ) appContext.getSystemService( Context.CONNECTIVITY_SERVICE );

        final NetworkInfo info = manager.getActiveNetworkInfo();

        return info != null && info.isConnected();
    }
}
