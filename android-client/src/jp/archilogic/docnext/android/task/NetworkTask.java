package jp.archilogic.docnext.android.task;

import java.io.IOException;

import jp.archilogic.docnext.android.type.TaskErrorType;
import jp.archilogic.docnext.android.util.ConnectivityUtil;
import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

public abstract class NetworkTask< Progress , Result > extends AsyncTask< Void , Progress , Result > {
    protected final Context _context;

    private boolean _networkUnavailable = false;
    private boolean _networkError = false;

    public NetworkTask( final Context context ) {
        _context = context;
    }

    protected abstract Result background() throws IOException;

    @Override
    protected final Result doInBackground( final Void ... params ) {
        if ( !ConnectivityUtil.isNetworkConnected( _context ) ) {
            _networkUnavailable = true;
            return null;
        }

        try {
            return background();
        } catch ( final IOException e ) {
            Log.d( "docnext" , "NetworkError" , e );

            _networkError = true;

            return null;
        }
    }

    protected abstract void onNetworkError( TaskErrorType error );

    @Override
    protected final void onPostExecute( final Result result ) {
        super.onPostExecute( result );

        if ( _networkUnavailable ) {
            onNetworkError( TaskErrorType.NETWORK_UNAVAILABLE );

            return;
        }

        if ( _networkError ) {
            onNetworkError( TaskErrorType.NETWORK_ERROR );

            return;
        }

        post( result );
    }

    protected abstract void post( Result result );
}