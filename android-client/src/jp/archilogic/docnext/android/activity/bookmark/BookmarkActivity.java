package jp.archilogic.docnext.android.activity.bookmark;

import java.util.List;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.BookmarkInfo;
import net.arnx.jsonic.JSONException;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.view.Display;
import android.view.LayoutInflater;
import android.view.Surface;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

public class BookmarkActivity extends Activity {
    public static final String EXTRA_PAGE = BookmarkActivity.class.getName() + "extra.page";
    public static final String EXTRA_LOCAL_DIR = BookmarkActivity.class.getName() + "extra.local.dir";

    private View _addButton;
    private ListView _listView;
    private View _emptyView;
    private String _localDir;
    private int _page;

    private ArrayAdapter< BookmarkInfo > _adapter;

    private final OnClickListener _addButtonClick = new OnClickListener() {
        @Override
        public void onClick( final View v ) {
            try {
                final List< BookmarkInfo > bookmarks = Kernel.getLocalProvider().getBookmarkInfo( _localDir );

                final BookmarkInfo bookmark = new BookmarkInfo( _page );

                if ( bookmarks.contains( bookmark ) ) {
                    throw new RuntimeException( "assert" );
                }

                bookmarks.add( bookmark );
                Kernel.getLocalProvider().setBookmarkInfo( _localDir , bookmarks );

                _adapter.clear();
                for ( final BookmarkInfo element : Kernel.getLocalProvider().getBookmarkInfo( _localDir ) ) {
                    _adapter.add( element );
                }

                bindAddButtonEnabled();
            } catch ( final NoMediaMountException e ) {
                e.printStackTrace();
                getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            } catch ( final JSONException e ) {
                e.printStackTrace();
                getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            }
        }
    };

    private final OnItemClickListener _itemClick = new OnItemClickListener() {
        @Override
        public void onItemClick( final AdapterView< ? > parent , final View view , final int position , final long id ) {
            try {
                final int p = _adapter.getItem( position ).page;
                goTo( p );
            } catch ( final JSONException e ) {
                e.printStackTrace();
                getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            }
        }
    };

    private void assignWidget() {
        _addButton = findViewById( R.id.addButton );
        _listView = ( ListView ) findViewById( R.id.listView );
        _emptyView = findViewById( R.id.listEmptyView );
    }

    private void bindAddButtonEnabled() {
        _addButton.setEnabled( !hasBookmarked() );
    }

    private void bindItem( final View convertView , final BookmarkInfo bookmark ) {
        try {
            final TextView titleTextView = ( TextView ) convertView.findViewById( R.id.titleTextView );
            final TextView pageTextView = ( TextView ) convertView.findViewById( R.id.pageTextView );
            final View deleteButton = convertView.findViewById( R.id.deleteButton );

            titleTextView.setText( bookmark.text );
            final int page = bookmark.page + 1;
            pageTextView.setText( Integer.toString( page ) );

            deleteButton.setOnClickListener( new OnClickListener() {
                @Override
                public void onClick( final View v ) {
                    try {
                        final List< BookmarkInfo > bookmarks = Kernel.getLocalProvider().getBookmarkInfo( _localDir );
                        bookmarks.remove( bookmark );
                        Kernel.getLocalProvider().setBookmarkInfo( _localDir , bookmarks );

                        _adapter.remove( bookmark );

                        bindAddButtonEnabled();
                    } catch ( final NoMediaMountException e ) {
                        e.printStackTrace();
                        getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
                    } catch ( final JSONException e ) {
                        e.printStackTrace();
                        getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
                    }
                }
            } );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    private void goTo( final int page ) {
        final Intent intent = new Intent();
        intent.putExtra( CoreViewActivity.EXTRA_PAGE , page );
        setResult( RESULT_OK , intent );
        finish();
    }

    private boolean hasBookmarked() {
        try {
            return Kernel.getLocalProvider().getBookmarkInfo( _localDir ).contains( new BookmarkInfo( _page ) );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }

        return false;
    }

    @Override
    public void onCreate( final Bundle savedInstanceState ) {
        super.onCreate( savedInstanceState );
        setContentView( R.layout.bookmark );
        rotateLock();

        try {
            _page = getIntent().getIntExtra( EXTRA_PAGE , 0 );
            _localDir = getIntent().getStringExtra( EXTRA_LOCAL_DIR );

            assignWidget();

            _addButton.setOnClickListener( _addButtonClick );
            bindAddButtonEnabled();

            _adapter = new ArrayAdapter< BookmarkInfo >( getApplicationContext() , -1 , Kernel.getLocalProvider().getBookmarkInfo( _localDir ) ) {
                @Override
                public View getView( final int position , View convertView , final ViewGroup parent ) {
                    if ( convertView == null ) {
                        convertView = LayoutInflater.from( getApplicationContext() ).inflate( R.layout.bookmark_item , parent , false );
                    }

                    bindItem( convertView , getItem( position ) );

                    return convertView;
                }
            };

            _listView.setAdapter( _adapter );
            _listView.setOnItemClickListener( _itemClick );
            _listView.setEmptyView( _emptyView );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    public void onRestoreInstanceState( final Bundle state ) {
        _page = state.getInt( EXTRA_PAGE );
        _localDir = state.getString( EXTRA_LOCAL_DIR );
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onSaveInstanceState( final Bundle state ) {
        state.putInt( EXTRA_PAGE , _page );
        state.putString( EXTRA_LOCAL_DIR , _localDir );
    }

    private void rotateLock() {
        if ( Build.VERSION.SDK_INT >= 9/* Build.VERSION_CODES.GINGERBREAD */) {
            final Display display = getWindowManager().getDefaultDisplay();
            int orientation = display.getOrientation();

            if ( display.getWidth() > display.getHeight() ) {
                if ( orientation == Surface.ROTATION_0 ) {
                    orientation = Surface.ROTATION_90;
                } else if ( orientation == Surface.ROTATION_180 ) {
                    orientation = Surface.ROTATION_270;
                }
            } else if ( display.getWidth() < display.getHeight() ) {
                if ( orientation == Surface.ROTATION_90 ) {
                    orientation = Surface.ROTATION_180;
                } else if ( orientation == Surface.ROTATION_270 ) {
                    orientation = Surface.ROTATION_0;
                }
            }

            switch ( orientation ) {
            case Surface.ROTATION_0:
                setRequestedOrientation( ActivityInfo.SCREEN_ORIENTATION_PORTRAIT );
                break;
            case Surface.ROTATION_90:
                setRequestedOrientation( ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE );
                break;
            case Surface.ROTATION_180:
                final int reversePortrait = 9;// ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT
                setRequestedOrientation( reversePortrait );
                break;
            case Surface.ROTATION_270:
                final int reverseLandscape = 8;// ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
                setRequestedOrientation( reverseLandscape );
                break;
            }
        } else {
            if ( getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT ) {
                setRequestedOrientation( ActivityInfo.SCREEN_ORIENTATION_PORTRAIT );
            } else {
                setRequestedOrientation( ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE );
            }
        }
    }
}
