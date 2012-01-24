package jp.archilogic.docnext.android.task;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.List;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;

import jp.archilogic.docnext.android.drm.Blowfish;
import jp.archilogic.docnext.android.provider.local.LocalPathManager;
import jp.archilogic.docnext.android.util.NetUtil;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import android.content.Context;

import com.google.common.base.Joiner;

public class ConcatDownloadTask extends BaseDownloadTask {
    private final String _remoteDir;
    private final List< String > _remoteNames;
    private final String _localDir;
    private final List< String > _localName;

    public ConcatDownloadTask( final Context context , final Receiver< Void > receiver , final String remoteDir , final List< String > remoteNames ,
            final String localDir , final List< String > localNames ) {
        super( context , receiver );

        if ( remoteNames.size() != localNames.size() ) {
            throw new RuntimeException( "assert. names size not match" );
        }

        _remoteDir = remoteDir;
        _remoteNames = remoteNames;
        _localDir = localDir;
        _localName = localNames;
    }

    @Override
    protected void download() throws IOException {
        InputStream in = null;

        try {
            final String remotePath = _remoteDir + "?names=" + Joiner.on( "," ).join( _remoteNames );

            in = new BufferedInputStream( NetUtil.get().get( remotePath ) , 8 * 1024 );

            for ( final String localName : _localName ) {
                if ( !procSingle( in , _localDir + localName ) ) {
                    return;
                }

                if ( isCancelled() ) {
                    return;
                }
            }
        } finally {
            IOUtils.closeQuietly( in );
        }
    }

    private boolean procSingle( final InputStream in , final String localPath ) throws IOException {
        new File( localPath + DOWNLOADING_POSTFIX ).createNewFile();

        final File workFile = new File( new LocalPathManager().getWorkingDownloadPath() );

        final byte[] length = new byte[ 8 ];
        for ( int pos = 0 ; pos < length.length ; ) {
            final int read = in.read( length , pos , length.length - pos );

            if ( read == -1 ) {
                throw new IOException( "assert. file count not match (less input)" );
            }

            pos += read;
        }

        final long size = ByteBuffer.wrap( length ).getLong();

        if ( !hasStorageSpace( size ) ) {
            _noStorageSpace = true;
            return false;
        }

        OutputStream out = null;
        Cipher cipher = Blowfish.getEncryptor();

        try {
            out = new BufferedOutputStream( FileUtils.openOutputStream( workFile ) , 8 * 1024 );

            final int BUF_SIZE = 1024 * 8;
            final byte[] buf = new byte[ BUF_SIZE ];

            for ( int pos = 0 ; pos < size ; ) {
                if ( isCancelled() ) {
                    return false;
                }

                final int read = in.read( buf , 0 , Math.min( BUF_SIZE , ( int ) ( size - pos ) ) );

                if ( read == -1 ) {
                    throw new IOException( "assert. unexpected EOF" );
                }

                //out.write( buf , 0 , read );
                byte[] encrypted = cipher.update( buf , 0 , read );
                if ( encrypted != null ) {
                    out.write( encrypted );
                }

                pos += read;
            }
            out.write( cipher.doFinal() );
        } catch (IllegalBlockSizeException e) {
            throw new RuntimeException();
        } catch (BadPaddingException e) {
            throw new RuntimeException();
        } finally {
            IOUtils.closeQuietly( out );
        }

        FileUtils.moveFile( workFile , new File( localPath ) );

        new File( localPath + DOWNLOADING_POSTFIX ).delete();
        onDownloadComplete();

        return true;
    }
}
