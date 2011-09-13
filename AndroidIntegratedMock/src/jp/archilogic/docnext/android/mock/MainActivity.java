package jp.archilogic.docnext.android.mock;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.ViewerFacade;
import jp.archilogic.docnext.android.service.DownloadService;
import net.arnx.jsonic.JSON;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import android.app.ListActivity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.common.collect.Lists;

public class MainActivity extends ListActivity {
    private static final int REQ_CODE_VIEWER = 123;

    private final MainActivity _self = this;

    private final List< View > _controls = Lists.newArrayList();;

    private final BroadcastReceiver _remoteProviderReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive( final Context context , final Intent intent ) {
            if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_PROGRESS ) ) {
                final int current = intent.getIntExtra( DownloadService.EXTRA_CURRENT , -1 );
                final int total = intent.getIntExtra( DownloadService.EXTRA_TOTAL , -1 );

                setProgress( Window.PROGRESS_END * current / total );
            } else if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_COMPLETED ) ) {
                setProgress( Window.PROGRESS_END );
                setProgressBarVisibility( false );
            } else if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_FAILED ) ) {
                setProgressBarVisibility( false );
            } else if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_ABORTED ) ) {
                setProgressBarVisibility( false );
            }
        }
    };

    public IntentFilter buildRemoteProviderReceiverFilter() {
        final IntentFilter filter = new IntentFilter();

        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_PROGRESS );
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_FAILED );
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_ABORTED );
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_COMPLETED );

        return filter;
    }

    private String getSaveDir( final String id ) {
        return Environment.getExternalStorageDirectory() + "/docnext/document/" + id + "/";
    }

    @Override
    public void onCreate( final Bundle savedInstanceState ) {
        super.onCreate( savedInstanceState );
        requestWindowFeature( Window.FEATURE_PROGRESS );
        setContentView( R.layout.main );

        registerReceiver( _remoteProviderReceiver , buildRemoteProviderReceiverFilter() );

        setListAdapter( new ArrayAdapter< DemoJSON >( _self , -1 , readDemos() ) {
            @Override
            public View getView( final int position , View convertView , final ViewGroup parent ) {
                if ( convertView == null ) {
                    convertView = LayoutInflater.from( getContext() ).inflate( R.layout.list_item , parent , false );

                    final View button = convertView.findViewById( R.id.deleteButton );
                    _controls.add( button );
                }

                final DemoJSON demo = getItem( position );

                final TextView textView = ( TextView ) convertView.findViewById( R.id.textView );
                final View deleteButton = convertView.findViewById( R.id.deleteButton );

                textView.setText( demo.name );
                deleteButton.setOnClickListener( new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        try {
                            FileUtils.deleteDirectory( new File( getSaveDir( demo.permitId ) ) );
                        } catch ( final IOException e ) {
                            throw new RuntimeException( e );
                        }
                    }
                } );

                return convertView;
            }
        } );

        final View reset = findViewById( R.id.reset );
        reset.setOnClickListener( new OnClickListener() {
            @Override
            public void onClick( final View v ) {
                try {
                    Kernel.getLocalProvider().setDownloadInfo( null );
                    startService( new Intent( _self , DownloadService.class ) );
                } catch ( final Exception e1 ) {
                    throw new RuntimeException( e1 );
                }

                setProgressBarVisibility( false );

                for ( final View view : _controls ) {
                    view.setEnabled( false );
                }

                new Handler().postDelayed( new Runnable() {
                    @Override
                    public void run() {
                        new AsyncTask< Void , Void , Void >() {
                            @Override
                            protected Void doInBackground( final Void ... params ) {
                                try {
                                    FileUtils.deleteDirectory( new File( Environment.getDataDirectory()
                                            + "/data/jp.archilogic.docnext.android.mock/files/" ) );
                                    FileUtils.deleteDirectory( new File( Environment.getExternalStorageDirectory() + "/docnext" ) );

                                    return null;
                                } catch ( final IOException e ) {
                                    throw new RuntimeException( e );
                                }
                            }

                            @Override
                            protected void onPostExecute( final Void result ) {
                                super.onPostExecute( result );

                                Toast.makeText( _self , R.string.message_reset_done , Toast.LENGTH_LONG ).show();

                                for ( final View view : _controls ) {
                                    view.setEnabled( true );
                                }
                            }
                        }.execute();
                    }
                } , 1000 );
            }
        } );

        _controls.add( getListView() );
        _controls.add( reset );
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        unregisterReceiver( _remoteProviderReceiver );
    }

    @Override
    protected void onListItemClick( final ListView l , final View v , final int position , final long id ) {
        final DemoJSON demo = ( DemoJSON ) getListAdapter().getItem( position );

        requestDocument( demo.permitId , demo.endpoint , demo.isSample );
    }

    private DemoJSON[] readDemos() {
        InputStream in = null;

        try {
            in = getAssets().open( "demo.json" );
            return JSON.decode( in , DemoJSON[].class );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } finally {
            IOUtils.closeQuietly( in );
        }
    }

    private void requestDocument( final String id , final String endpoint , final boolean isSample ) {
        final String saveDir = getSaveDir( id );

        // fake call
        Log.d( "hasAllFiles" , Integer.toString( ViewerFacade.getInstance().hasAllFiles( _self , id , saveDir ) ) );

        startActivityForResult( ViewerFacade.getInstance().getViewerIntent( _self , id , saveDir , isSample , endpoint ) , REQ_CODE_VIEWER );
    }
}
