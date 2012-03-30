package jp.archilogic.docnext.android.coreview.image;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.locks.ReentrantLock;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.coreview.image.CoreImageHighlight.HighlightColor;
import jp.archilogic.docnext.android.coreview.image.CoreImageRenderer.PageLoader;
import jp.archilogic.docnext.android.coreview.image.facingpages.Device;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.AnnotationInfo;
import jp.archilogic.docnext.android.info.ImageInfo;
import jp.archilogic.docnext.android.info.SizeInfo;
import jp.archilogic.docnext.android.provider.local.LocalPathManager;

import org.apache.lucene.index.Term;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.TermQuery;
import org.apache.lucene.store.FSDirectory;

import android.content.Context;
import android.content.Intent;
import android.graphics.PointF;
import android.graphics.RectF;

import com.google.common.collect.Lists;

/**
 * Handle non-OpenGL parameters
 */
public class CoreImageState implements PageHolder {
    interface OnPageChangedListener {
        void onPageChanged( int page );
    }

    interface OnPageChangeListener {
        void onPageChange( int page );
    }

    interface OnScaleChangeListener {
        /**
         * This is invoked by future value (ie. not current value)
         */
        void onScaleChange( boolean isMin , boolean isMax );
    }

    String id;
    String localDir;
    int page = 0;
    int pages;
    int minLevel;
    int maxLevel;
    ImageInfo image;
    CoreImageMatrix matrix = new CoreImageMatrix();
    SizeInfo pageSize;
    SizeInfo surfaceSize;
    CoreImageDirection direction;
    boolean isInteracting = false;
    List< CoreImageHighlight > highlights = Lists.newArrayList();

    Collection< Integer > spreadFirstPages;

    private final Context _context;
    private PageLoader _loader;

    private float _minScale;
    private float _maxScale;

    private final CoreImageCleanupValue _cleanup = new CoreImageCleanupValue();
    private boolean _preventCheckChangePage = false;
    private boolean _willGoNextPage = false;
    private boolean _willGoPrevPage = false;
    private OnScaleChangeListener _scaleChangeLisetener = null;
    private OnPageChangeListener _pageChangeListener = null;
    private OnPageChangedListener _pageChangedListener;
    private final ReentrantLock _lock = new ReentrantLock();

    private String _keyword;
    private final Executor _keywordTaskExecutor = Executors.newSingleThreadExecutor();
    private int _keywordTaskCount = 0;
    
    List< Set< AnnotationInfo >> overlay;

    CoreImageState( final Context context ) {
        _context = context;
    }

    private void bindKeyword() {
        _keywordTaskCount++;

        _keywordTaskExecutor.execute( new Runnable() {
            @Override
            public void run() {
                try {
                    highlights.clear();

                    if ( _keyword == null || _keywordTaskCount > 1 ) {
                        _keywordTaskCount--;
                        return;
                    }

                    Kernel.getLocalProvider().prepareImageTextIndex( localDir );

                    final IndexSearcher searcher =
                            new IndexSearcher( FSDirectory.open( new File( new LocalPathManager().getWorkingImageTextIndexDirPath() ) ) );

                    final String text =
                            searcher.doc( searcher.search( new TermQuery( new Term( "page" , Integer.toString( page ) ) ) , 1 ).scoreDocs[ 0 ].doc )
                                    .get( "text" );

                    final List< RectF > regions = Kernel.getLocalProvider().getImageRegions( localDir , page );
                    for ( int start = 0 ; ( start = text.indexOf( _keyword , start ) ) != -1 ; start += _keyword.length() ) {
                        for ( int delta = 0 ; delta < _keyword.length() ; delta++ ) {
                            final RectF r = regions.get( start + delta );

                            highlights.add( new CoreImageHighlight( r.left , r.top , r.right - r.left , r.bottom - r.top , HighlightColor.RED ) );
                        }
                    }

                    searcher.close();

                    Kernel.getLocalProvider().cleanupImageTextIndex();

                    _keywordTaskCount--;
                } catch ( final NoMediaMountException e ) {
                    e.printStackTrace();
                    _context.sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
                } catch ( final IOException e ) {
                    throw new RuntimeException( e );
                }
            }
        } );
    }

    private void changeToNextPage() {
        if ( _pageChangeListener != null ) {
            _pageChangeListener.onPageChange( page + 1 );
        }

        if ( page - 1 >= 0 ) {
            _loader.unload( page - 1 );
        }

        if ( page + 2 < pages ) {
            _loader.load( page + 2 );
        }

        page++;

        bindKeyword();

        if ( _pageChangedListener != null ) {
            _pageChangedListener.onPageChanged( page );
        }

        direction.updateOffset( this , true );
    }
    
    private void changeToPage( int destPage ) {
        if ( _pageChangeListener != null ) {
            _pageChangeListener.onPageChange( destPage );
        }

        for ( int delta = -1; delta <= 1; delta++ ) {
            _loader.unload( page + delta );
        }

        for ( int delta = -1; delta <= 1; delta++ ) {
            _loader.load( destPage + delta );
        }

        page = destPage;

        if ( _pageChangedListener != null ) {
            _pageChangedListener.onPageChanged( page );
        }
    }

    private void changeToPrevPage() {
        if ( _pageChangeListener != null ) {
            _pageChangeListener.onPageChange( page - 1 );
        }

        if ( page + 1 < pages ) {
            _loader.unload( page + 1 );
        }

        if ( page - 2 >= 0 ) {
            _loader.load( page - 2 );
        }

        page--;

        bindKeyword();

        if ( _pageChangedListener != null ) {
            _pageChangedListener.onPageChanged( page );
        }

        direction.updateOffset( this , false );
    }

    /**
     * @return isNext
     */
    private Boolean checkChangePage() {
        if ( direction.shouldChangeToNext( this ) && hasNextPage() ) {
            changeToNextPage();
            return true;
        } else if ( direction.shouldChangeToPrev( this ) && hasPrevPage() ) {
            changeToPrevPage();
            return false;
        }

        return null;
    }

    private void checkCleanup() {
        CoreImageCorner corner = null;

        if ( _preventCheckChangePage ) {
            _preventCheckChangePage = false;
        } else if ( _willGoNextPage ) {
            _willGoNextPage = false;

            changeToNextPage();
            corner = direction.getCorner( true );
        } else if ( _willGoPrevPage ) {
            _willGoPrevPage = false;

            changeToPrevPage();
            corner = direction.getCorner( false );
        } else {
            final Boolean isNext = checkChangePage();

            if ( isNext != null ) {
                corner = direction.getCorner( isNext );
            }
        }

        _cleanup.calcNormal( matrix , _minScale , _maxScale , pageSize , surfaceSize , corner );
    }

    void doubleTap( final PointF point ) {
        _cleanup.calcDoubleTap( point.x , point.y , matrix , _minScale , _maxScale , surfaceSize , getHorizontalPadding() , getVerticalPadding() );

        onScaleChange( _cleanup.dstMat.scale );
    }

    void drag( final PointF delta ) {
        final float EPS = 0.1f;

        if ( surfaceSize.width + EPS >= pageSize.width * matrix.scale && !direction.canMoveHorizontal() ) {
            delta.x = 0;
        }

        if ( surfaceSize.height + EPS >= pageSize.height * matrix.scale && !direction.canMoveVertical() ) {
            delta.y = 0;
        }

        matrix.tx -= delta.x;
        matrix.ty -= delta.y;
    }

    void fling( final PointF velocity ) {
        if ( matrix.isInPage( surfaceSize , pageSize ) && Math.hypot( velocity.x , velocity.y ) > 1000 ) {
            _cleanup.calcFling( velocity.x , velocity.y , matrix , pageSize , surfaceSize );
        }
    }

    float getHorizontalPadding() {
        return Math.max( surfaceSize.width - pageSize.width * Math.max( matrix.scale , _minScale ) , 0 ) / 2f;
    }

    @Override
    public int getPage() {
        return page;
    }

    float getVerticalPadding() {
        return Math.max( surfaceSize.height - pageSize.height * Math.max( matrix.scale , _minScale ) , 0 ) / 2f;
    }

    private boolean hasNextPage() {
        return page + 1 < pages;
    }

    private boolean hasPrevPage() {
        return page - 1 >= 0;
    }

    void initScale() {
        final boolean onlyUseHorizontal = Device.isSmartphone() && Device.isLandscape();
        _minScale =
                Math.min( 1f * surfaceSize.width / pageSize.width , onlyUseHorizontal ? Float.MAX_VALUE : 1f * surfaceSize.height / pageSize.height );

        _maxScale =
                Math.max(
                        maxLevel == image.maxLevel && image.isUseActualSize ? 1f * image.width / surfaceSize.width : ( float ) Math.pow( 2 , maxLevel
                                - minLevel ) , _minScale );

        matrix.scale = _minScale;

        onScaleChange( matrix.scale );
    }

    boolean isCleanup() {
        return _cleanup.isIn;
    }
    
    @SuppressWarnings("rawtypes")
    public void loadOverlay() {
        if ( !image.hasAnnotation ) {
            return;
        }

        try {
            overlay = new ArrayList< Set< AnnotationInfo >>();
            for ( int i = 0; i < pages; i++ ) {
                Map[] list = Kernel.getLocalProvider().annotation( localDir , i );
                Set< AnnotationInfo > set = new HashSet< AnnotationInfo >();

                for ( Map map : list ) {
                    @SuppressWarnings("unchecked")
                    AnnotationInfo info = new AnnotationInfo( map );
                    set.add( info );
                }
                overlay.add( set );
            }
        } catch (NoMediaMountException e) {
            e.printStackTrace();
        }
    }

    private boolean inRegion( final PointF point, final RectF region ) {
        RectF regionOnScreen = new RectF();

        regionOnScreen.left = matrix.tx + region.left * pageSize.width * matrix.scale + getHorizontalPadding();
        regionOnScreen.right = regionOnScreen.left + region.width() * pageSize.width * matrix.scale;
        regionOnScreen.top = matrix.ty + region.top * pageSize.height * matrix.scale + getVerticalPadding();
        regionOnScreen.bottom = regionOnScreen.top + region.height() * pageSize.height * matrix.scale;

        if ( regionOnScreen.contains( point.x , point.y ) ) {
            return true;
        }
        return false;
    }

    private boolean onTapAction( final PointF point ) {
        for ( AnnotationInfo info : overlay.get( page ) ) {
            if ( inRegion( point , info.region ) ) {
                String actionName = info.actionName;
                if ( actionName.equals( "GoToPage" ) ) {
                    changeToPage( info.page );
                    _willGoNextPage = false;
                    _willGoPrevPage = false;
                } else if ( actionName.equals( "URI" ) ) {
                    Intent intent = new Intent( CoreViewActivity.BROADCAST_OPEN_URL );
                    intent.putExtra( "uri" , info.uri );
                    _context.sendBroadcast( intent );
                } else if ( actionName.equals( "Movie" ) ) {
                    Intent intent = new Intent( CoreViewActivity.BROADCAST_PLAY_MOVIE );
                    intent.putExtra( "uri" , info.target );
                    _context.sendBroadcast( intent );
                }
                return true;
            }
        }
        return false;
    }

    private void onScaleChange( final float scale ) {
        final float EPS = ( float ) 1e-5;

        if ( _scaleChangeLisetener != null ) {
            _scaleChangeLisetener.onScaleChange( scale <= _minScale + EPS , scale >= _maxScale - EPS );
        }
    }

    void setKeyword( final String keyword ) {
        _keyword = keyword;
        bindKeyword();
    }

    void setOnPageChangedListener( final OnPageChangedListener l ) {
        _pageChangedListener = l;
    }

    void setOnPageChangeListener( final OnPageChangeListener l ) {
        _pageChangeListener = l;
    }

    void setOnScaleChangeListener( final OnScaleChangeListener l ) {
        _scaleChangeLisetener = l;
    }

    void setPageLoader( final PageLoader loader ) {
        _loader = loader;
    }

    void tap( final PointF point ) {
        final int THREASHOLD = 4;

        final float x = point.x - matrix.tx;
        final float y = point.y - matrix.ty;
        final int w = surfaceSize.width / THREASHOLD;
        final int h = surfaceSize.height / THREASHOLD;

        final int dx = x < w ? -1 : x > pageSize.width * matrix.scale - w ? 1 : 0;
        final int dy = y < h ? -1 : y > pageSize.height * matrix.scale - h ? 1 : 0;

        final int delta = dx * direction.toXSign() + dy * direction.toYSign();

        boolean tookAction = false;
        if ( overlay != null ) {
            tookAction = onTapAction( point );
        }
        
        if ( !tookAction ) {
            if ( delta > 0 && hasNextPage() ) {
                _willGoNextPage = true;
            } else if ( delta < 0 && hasPrevPage() ) {
                _willGoPrevPage = true;
            }
        }
        
    }

    /**
     * Check cleanup, Check change page, etc...
     */
    void update() {
        _lock.lock();

        try {
            if ( !isInteracting ) {
                if ( !_cleanup.isIn ) {
                    checkCleanup();
                }

                if ( _cleanup.isIn ) {
                    _cleanup.update( matrix , pageSize , surfaceSize );
                }
            } else {
                _cleanup.isIn = false;
            }
        } finally {
            _lock.unlock();
        }
    }

    void zoom( float scaleDelta , final PointF center ) {
        _lock.lock();
        try {
            if ( matrix.scale < _minScale || matrix.scale > _maxScale ) {
                scaleDelta = ( float ) Math.pow( scaleDelta , 0.2 );
            }

            final float hPad = getHorizontalPadding();
            final float vPad = getVerticalPadding();

            matrix.scale *= scaleDelta;

            matrix.tx = scaleDelta * ( matrix.tx - ( center.x - hPad ) ) + center.x - getHorizontalPadding();
            matrix.ty = scaleDelta * ( matrix.ty - ( center.y - vPad ) ) + center.y - getVerticalPadding();

            _preventCheckChangePage = true;

            onScaleChange( matrix.scale );
        } finally {
            _lock.unlock();
        }
    }

    void zoomByLevel( final int delta ) {
        _cleanup.calcLevelZoom( matrix , _minScale , _maxScale , surfaceSize , getHorizontalPadding() , getVerticalPadding() , delta );

        onScaleChange( _cleanup.dstMat.scale );
    }
}
