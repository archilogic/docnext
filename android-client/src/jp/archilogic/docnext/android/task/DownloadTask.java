package jp.archilogic.docnext.android.task;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.SocketTimeoutException;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;

import jp.archilogic.docnext.android.drm.Blowfish;
import jp.archilogic.docnext.android.provider.local.LocalPathManager;
import jp.archilogic.docnext.android.util.NetUtil;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import android.content.Context;
import android.util.Log;

public class DownloadTask extends BaseDownloadTask {
    private final String _remotePath;
    private final String _localPath;

    public DownloadTask( final Context context , final Receiver< Void > receiver , final String remotePath , final String localPath ) {
        super( context , receiver );

        _remotePath = remotePath;
        _localPath = localPath;
    }

    @Override
    protected void download() throws IOException {
        new File( _localPath + DOWNLOADING_POSTFIX ).createNewFile();

        boolean succeeded = false;
        int nRetry = 0;
        final File workFile = new File( new LocalPathManager().getWorkingDownloadPath() );

        do {
            try {
                InputStream in = new BufferedInputStream( NetUtil.get().get( _remotePath ) , 8 * 1024 );

                try {

                    OutputStream out = null;
                    Cipher c = Blowfish.getEncryptor();

                    try {
                        out = new BufferedOutputStream( FileUtils.openOutputStream( workFile ) , 8 * 1024 );

                        final int BUF_SIZE = 1024 * 8;
                        final byte[] buffer = new byte[ BUF_SIZE ];
                        for ( int n ; ( n = in.read( buffer ) ) != -1 ; ) {
                            if ( isCancelled() ) {
                                return;
                            }

                            final byte[] encrypted = c.doFinal( buffer , 0 , n );
                            out.write( encrypted , 0 , encrypted.length );
                        }
                        
                    } catch (IllegalBlockSizeException e) {
                        e.printStackTrace();
                    } catch (BadPaddingException e) {
                        e.printStackTrace();
                    } finally {
                        IOUtils.closeQuietly( out );
                    }
                } finally {
                    IOUtils.closeQuietly( in );
                }

                succeeded = true;
            } catch ( final SocketTimeoutException e ) {
                if ( nRetry > 0 ) {
                    throw e;
                }

                nRetry++;
            }
        } while ( !succeeded );

        if ( isCancelled() ) {
            return;
        }

        if ( !hasStorageSpace( workFile.length() ) ) {
            _noStorageSpace = true;
            return;
        }

        Log.d( "docnext" , _localPath );
        FileUtils.moveFile( workFile , new File( _localPath ) );

        new File( _localPath + DOWNLOADING_POSTFIX ).delete();
        onDownloadComplete();
    }
}
