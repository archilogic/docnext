package jp.archilogic.docnext.android.coreview.image;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.coreview.image.CoreImageRenderer.TextureBinder;
import jp.archilogic.docnext.android.drm.Blowfish;
import jp.archilogic.docnext.android.exception.NoMediaMountException;

import org.apache.commons.io.FileUtils;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.BitmapFactory.Options;
import android.util.Log;

public class LoadBitmapTask implements Runnable {
    public final int page;
    public final int level;

    private final int _px;
    private final int _py;

    private final PageHolder _pageHolder;
    private final String _localDir;
    private final Map< Integer , List< LoadBitmapTask > > _tasks;
    private final TextureBinder _binder;
    private final Context _context;
    private final int _threashold;
    private final boolean _isWebp;

    private boolean _cancelled = false;

    public LoadBitmapTask( final PageHolder pageHolder , final String localDir , final int page , final int level , final int px , final int py ,
            final Map< Integer , List< LoadBitmapTask > > tasks , final TextureBinder binder , final Context context , final int threashold ,
            final boolean isWebp ) {
        _pageHolder = pageHolder;
        _localDir = localDir;
        this.page = page;
        this.level = level;
        this._px = px;
        this._py = py;
        _tasks = tasks;
        _binder = binder;
        _context = context;
        _threashold = threashold;
        _isWebp = isWebp;
    }

    public void cancel() {
        _cancelled = true;
    }

    private Bitmap loadJpeg() {
        try {
            final String path = Kernel.getLocalProvider().getImageTexturePath( _localDir , page , level , _px , _py , false );

            final byte[] data = FileUtils.readFileToByteArray( new File( path ) );
            Cipher cipher = Blowfish.getDecryptor();

            final Options o = new Options();
            o.inPreferredConfig = Config.RGB_565;

            final byte[] decrypted = cipher.doFinal( data );
            final Bitmap ret = BitmapFactory.decodeByteArray( decrypted , 0 , decrypted.length , o );

            if ( ret == null ) {
                // for skia decoder problem (This seems to occur on low I/O performance)
                Log.w( "docnext" , "Failed to load bitmap. Will invoke error" );
                _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
                return null;
            }

            return ret;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );

            return null;
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } catch (IllegalBlockSizeException e) {
            e.printStackTrace();
            throw new RuntimeException( e );
        } catch (BadPaddingException e) {
            e.printStackTrace();
            throw new RuntimeException( e );
        }
    }

    private int loadWebp() {
        try {
            final String path = Kernel.getLocalProvider().getImageTexturePath( _localDir , page , level , _px , _py , true );

            final byte[] data = FileUtils.readFileToByteArray( new File( path ) );

            final Cipher cipher = Blowfish.getDecryptor();
            final byte[] decrypted = cipher.doFinal( data );
            return nativeLoad( decrypted );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );

            return 0;
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } catch (IllegalBlockSizeException e) {
            throw new RuntimeException();
        } catch (BadPaddingException e) {
            throw new RuntimeException();
        }
    }

    private native int nativeLoad( byte[] data );

    @Override
    public void run() {
        try {
            if ( !Kernel.getLocalProvider().isImageExists( _localDir , page , level , _px , _py , _isWebp ) ) {
                cancel();
            }

            if ( _cancelled ) {
                return;
            }

            if ( page < _pageHolder.getPage() - _threashold || page > _pageHolder.getPage() + _threashold ) {
                return;
            }

            _tasks.get( page ).remove( this );

            if ( _isWebp ) {
                _binder.bind( new BindQueueItem( page , level , _px , _py , loadWebp() ) );
            } else {
                _binder.bind( new BindQueueItem( page , level , _px , _py , loadJpeg() ) );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        }
    }
}
