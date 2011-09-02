package jp.archilogic.docnext.android.activity.toc;

import java.util.List;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.TOCElem;
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
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

public class TOCActivity extends Activity {
    public static final String EXTRA_LOCAL_DIR = TOCActivity.class.getName() + "extra.local.dir";

    private ListView _listView;
    private View _emptyView;
    private String _localDir;

    private final OnItemClickListener _itemClickListener = new OnItemClickListener() {
        @Override
        public void onItemClick( final AdapterView< ? > parent , final View view , final int position , final long id ) {
            try {
                goTo( Kernel.getLocalProvider().getInfo( _localDir ).toc.get( position ).page );
            } catch ( final NoMediaMountException e ) {
                e.printStackTrace();
                getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
            } catch ( final JSONException e ) {
                e.printStackTrace();
                getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
            }
        }
    };

    private void assignWidget() {
        _listView = ( ListView ) findViewById( R.id.listView );
        _emptyView = findViewById( R.id.listEmptyView );
    }

    private void bindItem( final View convertView , final TOCElem toc ) {
        final TextView titleTextView = ( TextView ) convertView.findViewById( R.id.titleTextView );
        final TextView pageTextView = ( TextView ) convertView.findViewById( R.id.pageTextView );

        titleTextView.setText( toc.text );
        pageTextView.setText( Integer.toString( toc.page + 1 ) );
    }

    private void goTo( final int page ) {
        final Intent intent = new Intent();
        intent.putExtra( CoreViewActivity.EXTRA_PAGE , page );
        setResult( RESULT_OK , intent );
        finish();
    }

    @Override
    public void onCreate( final Bundle savedInstanceState ) {
        super.onCreate( savedInstanceState );
        setContentView( R.layout.toc );
        rotateLock();

        try {
            _localDir = getIntent().getStringExtra( EXTRA_LOCAL_DIR );

            assignWidget();

            final List< TOCElem > list = Kernel.getLocalProvider().getInfo( _localDir ).toc;

            final ArrayAdapter< TOCElem > adapter = new ArrayAdapter< TOCElem >( getApplicationContext() , -1 , list ) {
                @Override
                public View getView( final int position , View convertView , final ViewGroup parent ) {
                    if ( convertView == null ) {
                        convertView = LayoutInflater.from( getContext() ).inflate( R.layout.toc_item , parent , false );
                    }

                    bindItem( convertView , getItem( position ) );

                    return convertView;
                }
            };

            _listView.setAdapter( adapter );
            _listView.setOnItemClickListener( _itemClickListener );
            _listView.setEmptyView( _emptyView );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getApplicationContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
        }
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    public void onRestoreInstanceState( final Bundle state ) {
        _localDir = state.getString( EXTRA_LOCAL_DIR );
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onSaveInstanceState( final Bundle state ) {
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
