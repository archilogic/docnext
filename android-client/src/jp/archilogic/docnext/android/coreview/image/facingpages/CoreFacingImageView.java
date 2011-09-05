package jp.archilogic.docnext.android.coreview.image.facingpages;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.coreview.CoreView;
import jp.archilogic.docnext.android.coreview.CoreViewDelegate;
import jp.archilogic.docnext.android.coreview.HasPage;
import jp.archilogic.docnext.android.coreview.Highlightable;
import jp.archilogic.docnext.android.coreview.NeedCleanup;
import jp.archilogic.docnext.android.coreview.image.facingpages.CoreImageState.OnScaleChangeListener;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.service.DownloadService;
import net.arnx.jsonic.JSONException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.PointF;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.os.Debug;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import android.widget.ZoomButtonsController;
import android.widget.ZoomButtonsController.OnZoomListener;

public class CoreFacingImageView extends FrameLayout implements CoreView , HasPage , NeedCleanup , Highlightable {
    private static final boolean DEBUG = false;

    private static final String STATE_PAGE = "page";

    private GLSurfaceView _glSurfaceView;

    private CoreImageRenderer _renderer;

    private ZoomButtonsController _zoomButtonsController = null;
    private ProgressBar _downloadIndicator;

    private final OnZoomListener _zoomButtonsControllerZoom = new OnZoomListener() {
        @Override
        public void onVisibilityChanged( final boolean visible ) {
        }

        @Override
        public void onZoom( final boolean zoomIn ) {
            _renderer.zoomByLevel( zoomIn ? 1 : -1 );
        }
    };

    private final OnScaleChangeListener _scaleChangeListener = new OnScaleChangeListener() {
        @Override
        public void onScaleChange( final boolean isMin , final boolean isMax ) {
            _zoomButtonsController.setZoomOutEnabled( !isMin );
            _zoomButtonsController.setZoomInEnabled( !isMax );
        }
    };

    private final BroadcastReceiver _remoteProviderReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive( final Context context , final Intent intent ) {
            if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_DOWNLOADED ) ) {
                final int page = intent.getIntExtra( DownloadService.EXTRA_PAGE , -1 );

                if ( page == getPage() ) {
                    refreshDownloadIndicator();
                }
            } else if ( intent.getAction().equals( HasPage.BROADCAST_PAGE_CHANGED ) ) {
                refreshDownloadIndicator();
            }
        }
    };

    public CoreFacingImageView( final Context context ) {
        super( context );

        LayoutInflater.from( context ).inflate( R.layout.core_image , this , true );

        assignWidget();

        _glSurfaceView.setDebugFlags( GLSurfaceView.DEBUG_CHECK_GL_ERROR | GLSurfaceView.DEBUG_LOG_GL_CALLS );

        _glSurfaceView.setRenderer( _renderer = new CoreImageRenderer( _glSurfaceView ) );
        _renderer.setDirection( CoreImageDirection.R2L );

        if ( Build.VERSION.SDK_INT < 8 ) {
            _renderer.setOnScaleChangeListener( _scaleChangeListener );

            _zoomButtonsController = new ZoomButtonsController( this );
            _zoomButtonsController.setOnZoomListener( _zoomButtonsControllerZoom );
        }

        final IntentFilter filter = new IntentFilter();
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_DOWNLOADED );
        filter.addAction( HasPage.BROADCAST_PAGE_CHANGED );
        getContext().registerReceiver( _remoteProviderReceiver , filter );
    }

    private void assignWidget() {
        _glSurfaceView = ( GLSurfaceView ) findViewById( R.id.glSurfaceView );
    }

    @Override
    public void cleanup() {
        getContext().unregisterReceiver( _remoteProviderReceiver );

        _glSurfaceView = null;
        _renderer.cleanup();
    }

    private int dip( final float value ) {
        return ( int ) TypedValue.applyDimension( TypedValue.COMPLEX_UNIT_DIP , value , getResources().getDisplayMetrics() );
    }

    @Override
    public int getPage() {
        return _renderer.getPage();
    }

    @Override
    public int getPages() {
        try {
            return Kernel.getLocalProvider().getInfo( _renderer.getLocalDir() ).pages;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
        return _renderer.getPage();
    }

    @Override
    public void highlight( final String keyword ) {
        _renderer.setKeyword( keyword );
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();

        if ( _zoomButtonsController != null ) {
            _zoomButtonsController.setVisible( false );
        }
    }

    @Override
    public void onDoubleTapGesture( final PointF point ) {
        _renderer.doubleTap( point );
    }

    @Override
    public void onDragGesture( final PointF delta ) {
        _renderer.drag( delta );
    }

    @Override
    public void onFlingGesture( final PointF velocity ) {
        _renderer.fling( velocity );
    }

    @Override
    public void onGestureBegin() {
        _renderer.beginInteraction();

        if ( _zoomButtonsController != null ) {
            _zoomButtonsController.setVisible( true );
        }
    }

    @Override
    public void onGestureEnd() {
        _renderer.endInteraction();
    }

    @Override
    public void onMenuVisibilityChange( final boolean isMenuVisible ) {
    }

    @Override
    public void onPause() {
        _glSurfaceView.onPause();

        if ( DEBUG ) {
            Debug.stopMethodTracing();
        }
    }

    @Override
    public void onResume() {
        if ( DEBUG ) {
            Debug.startMethodTracing();
        }

        _glSurfaceView.onResume();
    }

    @Override
    public void onTapGesture( final PointF point ) {
        _renderer.tap( point );
    }

    @Override
    public void onZoomGesture( final float scaleDelta , final PointF center ) {
        _renderer.zoom( scaleDelta , center );
    }

    private void refreshDownloadIndicator() {
        if ( _downloadIndicator != null ) {
            removeView( _downloadIndicator );
        }

        final int page = getPage();

        try {
            final DocInfo doc = Kernel.getLocalProvider().getInfo( _renderer.getLocalDir() );

            if ( page <= doc.pages && !Kernel.getLocalProvider().isAllImageExists( _renderer.getLocalDir() , page , getResources() ) ) {
                _downloadIndicator = new ProgressBar( getContext() );
                _downloadIndicator.setLayoutParams( new FrameLayout.LayoutParams( dip( 50 ) , dip( 50 ) , Gravity.CENTER ) );
                addView( _downloadIndicator );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    @Override
    public void restoreState( final Bundle state ) {
        _renderer.setPage( state.getInt( STATE_PAGE ) );
    }

    @Override
    public void saveState( final Bundle state ) {
        state.putInt( STATE_PAGE , _renderer.getPage() );
    }

    @Override
    public void setDelegate( final CoreViewDelegate delegate ) {
    }

    @Override
    public void setDocId( final String id ) {
        _renderer.setId( id );
    }

    @Override
    public void setLocalDir( final String localDir ) {
        _renderer.setLocalDir( localDir );
    }

    @Override
    public void setPage( final int page ) {
        _renderer.setPage( page );
    }
}
