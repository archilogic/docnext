package jp.archilogic.docnext.android;

import java.io.File;
import java.io.IOException;

import jp.archilogic.docnext.android.activity.CoreViewActivity;

import org.apache.commons.io.FileUtils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Environment;

public class ViewerFacade {
    public enum ResultExtra {
        NORMAL_FINISH , ERROR_ILLEGAL_ARGUMENT , ERROR_NO_SD_CARD , ERROR_BROKEN_FILE , ERROR_PERMISSION , ERROR_NO_STORAGE_SPACE , ERROR_NETWORK;
    }

    public static final String EXTRA_RESULT = ViewerFacade.class.getName() + ".extra.result";

    public static final int HAS_ALL_FILES_OK = 0;
    public static final int HAS_ALL_FILES_NOT_ALL = 1;
    // This means problem occurs with SD
    public static final int HAS_ALL_FILES_NO_SD = 2;
    public static final int HAS_ALL_FILES_ERROR = 99;

    private static ViewerFacade _instance = null;

    public static ViewerFacade getInstance() {
        if ( _instance == null ) {
            _instance = new ViewerFacade();
        }

        return _instance;
    }

    private ViewerFacade() {
    }

    /**
     * @param downloadEndpoint
     *            root path for document. i.e.) #{endpont}/info.json
     */
    public Intent getViewerIntent( final Context packageContext , final String permitId , final String saveDir , final boolean isSample ,
            final String downloadEndpoint ) {
        // TODO storageFlag

        // Fail-safe delete
        if ( !new File( String.format( CoreViewActivity.SAMPLE_LOCAL_DIR_FORMAT , permitId ) ).exists()
                && new File( CoreViewActivity.SAMPLE_LOCAL_DIR_CHILD ).exists()
                && new File( CoreViewActivity.SAMPLE_LOCAL_DIR_CHILD ).list().length > 0 ) {
            new AsyncTask< Void , Void , Void >() {
                @Override
                protected Void doInBackground( final Void ... params ) {
                    try {
                        for ( final File f : new File( CoreViewActivity.SAMPLE_LOCAL_DIR_CHILD ).listFiles() ) {
                            FileUtils.deleteDirectory( f );
                        }
                    } catch ( final IOException e ) {
                        throw new RuntimeException( e );
                    }
                    return null;
                }
            }.execute();
        }

        return new Intent( packageContext , CoreViewActivity.class ).putExtra( CoreViewActivity.EXTRA_ID , permitId )
                .putExtra( CoreViewActivity.EXTRA_LOCAL_DIR , saveDir ).putExtra( CoreViewActivity.EXTRA_ENDPOINT , downloadEndpoint )
                .putExtra( CoreViewActivity.EXTRA_IS_SAMPLE , isSample );
    }

    public int hasAllFiles( final Context context , final String permitId , final String saveDir ) {
        int ret = HAS_ALL_FILES_OK;
        int mesId = -1;

        try {
            if ( !Kernel.getLocalProvider().isCompleted( saveDir ) ) {
                ret = HAS_ALL_FILES_NOT_ALL;
            }

            if ( !Environment.MEDIA_MOUNTED.equals( Environment.getExternalStorageState() ) ) {
                ret = HAS_ALL_FILES_NO_SD;
                mesId = R.string.no_sdcard_error;
            }
        } catch ( final Exception e ) {
            e.printStackTrace();
            ret = HAS_ALL_FILES_ERROR;
            mesId = R.string.unexpected_error;
        }

        if ( mesId != -1 ) {
            new AlertDialog.Builder( context ).setMessage( mesId ).setPositiveButton( R.string.ok , null ).show();
        }

        return ret;
    }
}
