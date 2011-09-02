package jp.archilogic.docnext.android.coreview.thumbnail;

import java.io.File;
import java.io.IOException;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.provider.local.LocalProvider;
import net.arnx.jsonic.JSONException;

import org.apache.commons.io.FileUtils;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Gallery;
import android.widget.ImageView;

public class ThumbnailImageAdapter extends BaseAdapter {
    public enum Direction {
        LEFT , RIGHT;
    }

    private final LocalProvider provider = Kernel.getLocalProvider();

    private final String _localDir;
    private final Context _context;
    private final Direction _direction;

    private int _count;

    public ThumbnailImageAdapter( final Context context , final String id , final String localDir , final Direction direction ) {
        _localDir = localDir;
        _context = context;
        _direction = direction;

        try {
            final DocInfo doc = provider.getInfo( _localDir );
            _count = doc.pages;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
        }
    }

    private Bitmap getBitmap( final int page ) {
        try {
            final String path = provider.getImageThumbnailPath( _localDir , page );

            if ( path == null ) {
                throw new RuntimeException( "Can't be here" );
            }

            final byte[] data = FileUtils.readFileToByteArray( new File( path ) );

            return BitmapFactory.decodeByteArray( data , 0 , data.length );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }

        return null;
    }

    @Override
    public int getCount() {
        return _count;
    }

    @Override
    public Object getItem( final int position ) {
        return null;
    }

    @Override
    public long getItemId( final int position ) {
        return 0;
    }

    @Override
    public View getView( final int position , final View convertView , final ViewGroup parent ) {
        ImageView view;

        if ( convertView == null ) {
            view = new ImageView( _context );

            view.setScaleType( ImageView.ScaleType.FIT_CENTER );
            view.setLayoutParams( new Gallery.LayoutParams( 200 , 256 ) );
        } else {
            view = ( ImageView ) convertView;
        }

        view.setImageBitmap( getBitmap( _direction == Direction.LEFT ? getCount() - position - 1 : position ) );

        return view;
    }
}
