package jp.archilogic.docnext.android.widget;

import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.service.DownloadService;
import android.R.attr;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ProgressBar;

public class CoreViewStatusBar extends LinearLayout {
    private ProgressBar _progressBar;
    private boolean _hasReceiverRegistered = false;

    private final BroadcastReceiver _remoteProviderReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive( final Context context , final Intent intent ) {
            if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_PROGRESS ) ) {
                final int current = intent.getIntExtra( DownloadService.EXTRA_CURRENT , -1 );
                final int total = intent.getIntExtra( DownloadService.EXTRA_TOTAL , -1 );

                _progressBar.setMax( total );
                _progressBar.setProgress( current );
            } else if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_COMPLETED ) ) {
                _progressBar.setVisibility( INVISIBLE );

                getContext().unregisterReceiver( _remoteProviderReceiver );
                _hasReceiverRegistered = false;
            }
        }
    };

    public CoreViewStatusBar( final Context context ) {
        super( context );

        setLayoutParams( new FrameLayout.LayoutParams( FrameLayout.LayoutParams.FILL_PARENT , FrameLayout.LayoutParams.WRAP_CONTENT , Gravity.BOTTOM ) );
        setOrientation( LinearLayout.VERTICAL );
        setBackgroundColor( 0x80000000 );
        setPadding( dp( 5 ) , dp( 10 ) , dp( 5 ) , dp( 10 ) );
        setVisibility( GONE );

        buildProgressBar();
    }

    private void buildProgressBar() {
        final int style = attr.progressBarStyleHorizontal;
        _progressBar = new ProgressBar( getContext() , null , style );

        _progressBar.setLayoutParams( new LinearLayout.LayoutParams( LinearLayout.LayoutParams.FILL_PARENT , LinearLayout.LayoutParams.WRAP_CONTENT ,
                Gravity.BOTTOM ) );
        _progressBar.setProgressDrawable( getResources().getDrawable( R.drawable.progress_horizontal ) );
        addView( _progressBar );

        final IntentFilter filter = new IntentFilter();
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_PROGRESS );
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_COMPLETED );
        getContext().registerReceiver( _remoteProviderReceiver , filter );
        _hasReceiverRegistered = true;
    }

    private int dp( final float value ) {
        final float density = getResources().getDisplayMetrics().density;

        return Math.round( value * density );
    }

    public float getProgress() {
        return 1f * _progressBar.getProgress() / _progressBar.getMax();
    }

    public void onDestroy() {
        if ( _hasReceiverRegistered ) {
            getContext().unregisterReceiver( _remoteProviderReceiver );
        }
    }

    public void setProgress( final float progress ) {
        _progressBar.setProgress( Math.round( progress * _progressBar.getMax() ) );
    }
}
