package jp.archilogic.docnext.android.task;

import java.io.IOException;

import jp.archilogic.docnext.android.exception.HttpStatusCodeException;
import jp.archilogic.docnext.android.type.TaskErrorType;
import android.content.Context;
import android.os.Environment;
import android.os.StatFs;
import android.util.Log;

public abstract class BaseDownloadTask extends NetworkTask< Void , Void > {
    public static final String DOWNLOADING_POSTFIX = "_downloading";

    private final Receiver< Void > _receiver;
    private final StatFs _stat;

    private boolean _storageNotMounted = false;
    protected boolean _noStorageSpace = false;
    private HttpStatusCodeException _httpError = null;

    public BaseDownloadTask( final Context context , final Receiver< Void > receiver ) {
        super( context );

        _receiver = receiver;

        _stat = new StatFs( Environment.getExternalStorageDirectory().getPath() );
    }

    @Override
    protected final Void background() throws IOException {
        try {
            if ( !Environment.MEDIA_MOUNTED.equals( Environment.getExternalStorageState() ) ) {
                _storageNotMounted = true;
                return null;
            }

            download();

            return null;
        } catch ( final HttpStatusCodeException e ) {
            Log.e( "docnext" , "HttpStatusCodeException" , e );
            _httpError = e;
            return null;
        }
    }

    protected abstract void download() throws IOException;

    protected boolean hasStorageSpace( final long length ) {
        final long availableBlocks = _stat.getAvailableBlocks();
        final long blockSize = _stat.getBlockSize();

        return availableBlocks * blockSize >= length;
    }

    @Override
    protected void onCancelled() {
        super.onCancelled();

        if ( _receiver instanceof FileReceiver ) {
            ( ( FileReceiver< Void > ) _receiver ).cancelled();
        }
    }

    protected void onDownloadComplete() {
        if ( _receiver instanceof FileReceiver ) {
            ( ( FileReceiver< Void > ) _receiver ).downloadComplete();
        }
    }

    @Override
    protected void onNetworkError( final TaskErrorType error ) {
        _receiver.error( error );
    }

    @Override
    protected final void post( final Void result ) {
        if ( _storageNotMounted ) {
            onNetworkError( TaskErrorType.STORAGE_NOT_MOUNTED );
            return;
        }

        if ( _noStorageSpace ) {
            onNetworkError( TaskErrorType.NO_STORAGE_SPACE );
            return;
        }

        if ( _httpError != null ) {
            Log.d( "docnext" , "HTTPError" + _httpError.getStatusCode() + ": " + _httpError.getResponseBody() );

            onNetworkError( TaskErrorType.NETWORK_ERROR );

            return;
        }

        _receiver.receive( result );
    }
}
