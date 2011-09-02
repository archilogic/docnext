package jp.archilogic.docnext.android.coreview.image.facingpages;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.coreview.HasPage;
import jp.archilogic.docnext.android.coreview.image.BindQueueItem;
import jp.archilogic.docnext.android.coreview.image.CoreImageRenderer.TextureBinder;
import jp.archilogic.docnext.android.coreview.image.ImageLoadQueue;
import jp.archilogic.docnext.android.coreview.image.LoadBitmapTask;
import jp.archilogic.docnext.android.coreview.image.UnbindQueueItem;
import jp.archilogic.docnext.android.coreview.image.facingpages.CoreImageState.OnPageChangeListener;
import jp.archilogic.docnext.android.coreview.image.facingpages.CoreImageState.OnPageChangedListener;
import jp.archilogic.docnext.android.coreview.image.facingpages.CoreImageState.OnScaleChangeListener;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.info.SizeInfo;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import jp.archilogic.docnext.android.service.DownloadService;
import jp.archilogic.docnext.android.type.BindingType;
import jp.archilogic.docnext.android.util.ImageLevelUtil;
import net.arnx.jsonic.JSONException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.PointF;
import android.opengl.GLES10;
import android.opengl.GLES11;
import android.opengl.GLSurfaceView;
import android.opengl.GLSurfaceView.Renderer;
import android.os.SystemClock;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

/**
 * Handle OpenGL features
 */
public class CoreImageRenderer implements Renderer {
    interface PageLoader {
        void load( int page );

        void unload( int page );
    }

    private final GLSurfaceView _view;
    private Context _context;
    private final CoreImageState _state;
    private final CoreImageRenderEngine _renderEngine;

    private final ImageLoadQueue _imageLoadQueue = new ImageLoadQueue();
    private final ExecutorService _executor = new ThreadPoolExecutor( 1 , 1 , 0L , TimeUnit.MILLISECONDS , _imageLoadQueue );
    private final Map< Integer , List< LoadBitmapTask > > _tasks = Maps.newHashMap();
    private boolean _initialized = false;

    int _fpsCounter = 0;
    long _fpsTime;
    long _frameSum;

    private final PageLoader _loader = new PageLoader() {
        @Override
        public void load( final int page ) {
            if ( page < 0 || page >= _state.pages ) {
                return;
            }

            if ( _tasks.get( page ) == null ) {
                _tasks.put( page , Lists.< LoadBitmapTask > newArrayList() );
            }

            final int[][] dimen = _renderEngine.getTextureDimension( page );
            for ( int level = _state.minLevel ; level <= _state.maxLevel ; level++ ) {
                for ( int py = 0 ; py < dimen[ level - _state.minLevel ][ 1 ] ; py++ ) {
                    for ( int px = 0 ; px < dimen[ level - _state.minLevel ][ 0 ] ; px++ ) {
                        final LoadBitmapTask task =
                                new LoadBitmapTask( _state , _state.localDir , page , level , px , py , _tasks , _binder , _context , 4 ,
                                        _state.image.isWebp );

                        _tasks.get( page ).add( task );
                        _executor.execute( task );
                    }
                }
            }
        }

        @Override
        public void unload( final int page ) {
            if ( page < 0 || page >= _state.pages ) {
                return;
            }

            if ( _tasks.get( page ) != null ) {
                for ( final LoadBitmapTask task : _tasks.get( page ) ) {
                    task.cancel();
                }

                _tasks.remove( page );
            }

            // unbind all
            final int[][] dimen = _renderEngine.getTextureDimension( page );
            for ( int level = _state.minLevel ; level <= _state.maxLevel ; level++ ) {
                for ( int py = 0 ; py < dimen[ level - _state.minLevel ][ 1 ] ; py++ ) {
                    for ( int px = 0 ; px < dimen[ level - _state.minLevel ][ 0 ] ; px++ ) {
                        final UnbindQueueItem item = new UnbindQueueItem( page , level , px , py );

                        _view.queueEvent( new Runnable() {
                            @Override
                            public void run() {
                                _renderEngine.unbindPageImage( item , _state.minLevel );
                            }
                        } );
                    }
                }
            }
        }
    };

    private final TextureBinder _binder = new TextureBinder() {
        @Override
        public void bind( final BindQueueItem item ) {
            _view.queueEvent( new Runnable() {
                @Override
                public void run() {
                    _renderEngine.bindPageImage( item , _state.minLevel );
                }
            } );
        }
    };

    private final OnPageChangeListener _pageChangeListener = new OnPageChangeListener() {
        @Override
        public void onPageChange( final int page ) {
            _imageLoadQueue.setPage( page );
        }
    };

    private final OnPageChangedListener _pageChangedListener = new OnPageChangedListener() {
        @Override
        public void onPageChanged( final int page ) {
            _context.sendBroadcast( new Intent( HasPage.BROADCAST_PAGE_CHANGED ).putExtra( HasPage.BROADCAST_EXTRA_PAGE , page ) );
        }
    };

    private final BroadcastReceiver _remoteProviderReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive( final Context context , final Intent intent ) {
            try {
                if ( intent.getAction().equals( DownloadService.BROADCAST_DOWNLOAD_DOWNLOADED ) ) {
                    final int page = intent.getIntExtra( DownloadService.EXTRA_PAGE , -1 );
                    final int level = intent.getIntExtra( DownloadService.EXTRA_LEVEL , -1 );
                    final int px = intent.getIntExtra( DownloadService.EXTRA_PX , -1 );
                    final int py = intent.getIntExtra( DownloadService.EXTRA_PY , -1 );

                    if ( _state.image == null ) {
                        _state.image = Kernel.getLocalProvider().getImageInfo( _state.localDir );
                    }

                    if ( _tasks.get( page ) == null ) {
                        _tasks.put( page , Lists.< LoadBitmapTask > newArrayList() );
                    }

                    if ( Math.abs( page - _state.page ) <= 3 ) {
                        final LoadBitmapTask task =
                                new LoadBitmapTask( _state , _state.localDir , page , level , px , py , _tasks , _binder , _context , 4 ,
                                        _state.image.isWebp );

                        _tasks.get( page ).add( task );
                        _executor.execute( task );
                    }
                }
            } catch ( final JSONException e ) {
                throw new RuntimeException( e );
            } catch ( final NoMediaMountException e ) {
                throw new RuntimeException( e );
            }
        }
    };

    public CoreImageRenderer( final GLSurfaceView view ) {
        _view = view;
        _context = view.getContext();
        _renderEngine = new CoreImageRenderEngine();
        _state = new CoreImageState( _context );
        _state.setPageLoader( _loader );
        _state.setOnPageChangeListener( _pageChangeListener );
        _state.setOnPageChangedListener( _pageChangedListener );

        final IntentFilter filter = new IntentFilter();
        filter.addAction( DownloadService.BROADCAST_DOWNLOAD_DOWNLOADED );
        _context.registerReceiver( _remoteProviderReceiver , filter );
    }

    void beginInteraction() {
        if ( _initialized ) {
            _state.isInteracting = true;
        }
    }

    void cleanup() {
        _context.unregisterReceiver( _remoteProviderReceiver );

        _renderEngine.cleanup();
        _context = null;
        _imageLoadQueue.clear();
    }

    void doubleTap( final PointF point ) {
        if ( _initialized ) {
            _state.doubleTap( point );
        }
    }

    void drag( final PointF delta ) {
        if ( _initialized ) {
            _state.drag( delta );
        }
    }

    void endInteraction() {
        if ( _initialized ) {
            _state.isInteracting = false;
        }
    }

    void fling( final PointF velocity ) {
        if ( _initialized ) {
            _state.fling( velocity );
        }
    }

    String getLocalDir() {
        return _state.localDir;
    }

    int getPage() {
        return _state.page;
    }

    @Override
    public void onDrawFrame( final GL10 gl ) {
        final long t = SystemClock.elapsedRealtime();

        _state.update();
        _renderEngine.render( _state );

        _fpsCounter++;
        _frameSum += SystemClock.elapsedRealtime() - t;
        if ( _fpsCounter == 120 ) {
            // System.err.println( "FPS: " + 120.0 * 1000
            // / ( SystemClock.elapsedRealtime() - _fpsTime ) + ", avg: " + _frameSum / 120.0 );

            _fpsTime = SystemClock.elapsedRealtime();
            _fpsCounter = 0;
            _frameSum = 0;

            System.err.println( "Mem: " + Runtime.getRuntime().freeMemory() + ", " + Runtime.getRuntime().maxMemory() );
        }
    }

    @Override
    public void onSurfaceChanged( final GL10 gl , final int width , final int height ) {
        GLES10.glEnable( GLES10.GL_TEXTURE_2D );
        GLES10.glEnable( GLES10.GL_BLEND );
        // GLES10.glBlendFunc( GLES10.GL_SRC_ALPHA , GLES10.GL_ONE_MINUS_SRC_ALPHA ) seems not valid
        GLES10.glBlendFunc( GLES10.GL_ONE , GLES10.GL_ONE_MINUS_SRC_ALPHA );
        GLES10.glEnable( GLES10.GL_ALPHA_BITS );

        _state.surfaceSize = new SizeInfo( width , height );
        _state.initScale();

        _renderEngine.prepare( _context , _state.pages , _state.minLevel , _state.maxLevel , _state.pageSize , _state.surfaceSize , _state.image );

        for ( int i = -3 ; i <= 3 ; i++ ) {
            _loader.load( _state.page + i );
        }

        final int[] caps =
                { GLES11.GL_ALPHA_TEST , GLES11.GL_BLEND , GLES11.GL_CLIP_PLANE0 , GLES11.GL_CLIP_PLANE1 , GLES11.GL_CLIP_PLANE2 ,
                        GLES11.GL_CLIP_PLANE3 , GLES11.GL_CLIP_PLANE4 , GLES11.GL_CLIP_PLANE5 , GLES11.GL_COLOR_LOGIC_OP , GLES11.GL_COLOR_MATERIAL ,
                        GLES11.GL_CULL_FACE , GLES11.GL_DEPTH_TEST , GLES11.GL_DITHER , GLES11.GL_FOG , GLES11.GL_LIGHT0 , GLES11.GL_LIGHT1 ,
                        GLES11.GL_LIGHT2 , GLES11.GL_LIGHT3 , GLES11.GL_LIGHT4 , GLES11.GL_LIGHT5 , GLES11.GL_LIGHT6 , GLES11.GL_LIGHT7 ,
                        GLES11.GL_LIGHTING , GLES11.GL_LINE_SMOOTH , GLES11.GL_MULTISAMPLE , GLES11.GL_NORMALIZE , GLES11.GL_POINT_SMOOTH ,
                        GLES11.GL_POLYGON_OFFSET_FILL , GLES11.GL_RESCALE_NORMAL , GLES11.GL_SAMPLE_ALPHA_TO_COVERAGE ,
                        GLES11.GL_SAMPLE_ALPHA_TO_ONE , GLES11.GL_SAMPLE_COVERAGE , GLES11.GL_SCISSOR_TEST , GLES11.GL_STENCIL_TEST ,
                        GLES11.GL_TEXTURE_2D };
        final String[] names =
                { "GL11.GL_ALPHA_TEST" , "GL11.GL_BLEND" , "GL11.GL_CLIP_PLANE0" , "GL11.GL_CLIP_PLANE1" , "GL11.GL_CLIP_PLANE2" ,
                        "GL11.GL_CLIP_PLANE3" , "GL11.GL_CLIP_PLANE4" , "GL11.GL_CLIP_PLANE5" , "GL11.GL_COLOR_LOGIC_OP" , "GL11.GL_COLOR_MATERIAL" ,
                        "GL11.GL_CULL_FACE" , "GL11.GL_DEPTH_TEST" , "GL11.GL_DITHER" , "GL11.GL_FOG" , "GL11.GL_LIGHT0" , "GL11.GL_LIGHT1" ,
                        "GL11.GL_LIGHT2" , "GL11.GL_LIGHT3" , "GL11.GL_LIGHT4" , "GL11.GL_LIGHT5" , "GL11.GL_LIGHT6" , "GL11.GL_LIGHT7" ,
                        "GL11.GL_LIGHTING" , "GL11.GL_LINE_SMOOTH" , "GL11.GL_MULTISAMPLE" , "GL11.GL_NORMALIZE" , "GL11.GL_POINT_SMOOTH" ,
                        "GL11.GL_POLYGON_OFFSET_FILL" , "GL11.GL_RESCALE_NORMAL" , "GL11.GL_SAMPLE_ALPHA_TO_COVERAGE" ,
                        "GL11.GL_SAMPLE_ALPHA_TO_ONE" , "GL11.GL_SAMPLE_COVERAGE" , "GL11.GL_SCISSOR_TEST" , "GL11.GL_STENCIL_TEST" ,
                        "GL11.GL_TEXTURE_2D" };

        for ( int index = 0 ; index < caps.length ; index++ ) {
            System.err.println( names[ index ] + ": " + GLES11.glIsEnabled( caps[ index ] ) );
        }

        _initialized = true;
    }

    @Override
    public void onSurfaceCreated( final GL10 gl , final EGLConfig config ) {
        try {
            final DocInfo doc = Kernel.getLocalProvider().getInfo( _state.localDir );
            _state.image = Kernel.getLocalProvider().getImageInfo( _state.localDir );

            setDirection( doc.binding == BindingType.LEFT ? CoreImageDirection.L2R : CoreImageDirection.R2L );

            _state.minLevel = ImageLevelUtil.getMinLevel( _context.getResources() , _state.image.maxLevel );
            _state.maxLevel = ImageLevelUtil.getMaxLevel( _state.minLevel , _state.image.maxLevel , _state.image.maxNumberOfLevel );

            final int width =
                    _state.minLevel != _state.image.maxLevel || !_state.image.isUseActualSize ? ( int ) ( RemoteProvider.TEXTURE_SIZE * Math.pow( 2 ,
                            _state.minLevel ) ) : _state.image.width;
            _state.pageSize = new SizeInfo( width , _state.image.height * width / _state.image.width );

            _state.pages = doc.pages;

            _state.facingFirstPages = Kernel.getLocalProvider().getSpreadFirstPages( _state.localDir );

            if ( _state.facingFirstPages.contains( _state.page ) ) {
                _state.page++;
            }

            Device.setState( _state );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_NO_SDCARD_ERROR ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_BROKEN_FILE_ERROR ) );
        }
    }

    void setDirection( final CoreImageDirection direction ) {
        _state.direction = direction;
    }

    void setId( final String id ) {
        _state.id = id;
    }

    void setKeyword( final String keyword ) {
        _state.setKeyword( keyword );
    }

    void setLocalDir( final String localDir ) {
        _state.localDir = localDir;
    }

    void setOnScaleChangeListener( final OnScaleChangeListener l ) {
        _state.setOnScaleChangeListener( l );
    }

    void setPage( final int page ) {
        for ( int i = -3 ; i <= 3 ; i++ ) {
            _loader.unload( _state.page + i );
        }

        _state.page = page;

        for ( int i = -3 ; i <= 3 ; i++ ) {
            _loader.load( _state.page + i );
        }
    }

    void tap( final PointF point ) {
        if ( _initialized ) {
            _state.tap( point );
        }
    }

    void zoom( final float scaleDelta , final PointF center ) {
        if ( _initialized ) {
            _state.zoom( scaleDelta , center );
        }
    }

    void zoomByLevel( final int delta ) {
        if ( _initialized ) {
            _state.zoomByLevel( delta );
        }
    }
}
