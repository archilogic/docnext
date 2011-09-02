package jp.archilogic.docnext.android.coreview.image;

import java.util.List;

import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.coreview.image.PageInfo.PageTextureStatus;
import jp.archilogic.docnext.android.info.ImageInfo;
import jp.archilogic.docnext.android.info.SizeFInfo;
import jp.archilogic.docnext.android.info.SizeInfo;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Point;
import android.opengl.GLES10;
import android.opengl.GLES11Ext;
import android.os.SystemClock;

import com.google.common.collect.Lists;

public class CoreImageRenderEngine {
    static {
        System.loadLibrary( "NativeWebp" );
    }

    private static final int PAGE_MARGIN = 30;

    private TextureInfo _background;
    private TextureInfo _blank;
    private TextureInfo _red;
    private PageInfo[] _pages;

    // to avoid GC
    private final CoreImageMatrix _immutableMatrix = new CoreImageMatrix();
    private final SizeFInfo _immutablePadding = new SizeFInfo( 0 , 0 );

    int _fpsCounter = 0;
    long _fpsTime;
    long _frameSum;

    void bindPageImage( final BindQueueItem item , final int minLevel ) {
        final TextureInfo texture = _pages[ item.page ].textures[ item.level - minLevel ][ item.py ][ item.px ];

        if ( item.isWebp ) {
            texture.bindTexture( item.pointer );
            nativeUnload( item.pointer );
        } else {
            texture.bindTexture( item.bitmap );
            item.bitmap.recycle();
        }

        _pages[ item.page ].statuses[ item.level - minLevel ][ item.py ][ item.px ] = PageTextureStatus.BIND;
    }

    private void checkAndDrawSingleImage( final boolean isFirst , final TextureInfo[][] textures , final PageTextureStatus[][] statuses ,
            final int py , final int px , final int x , final int y , final int w , final int h , final SizeInfo surface ) {
        final boolean isVisible = x + w >= 0 && x < surface.width && y + h >= 0 && y < surface.height;

        if ( isVisible ) {
            if ( statuses[ py ][ px ] == PageTextureStatus.BIND ) {
                drawSingleImage( textures[ py ][ px ].id , x , y , w , h );
            } else if ( isFirst ) {
                drawSingleImage( _blank.id , x , y , w , h );
            }
        }
    }

    void cleanup() {
        // in case, called before prepare (This occured when onCreate called twice (mainly for Galaxy S))
        if ( _pages == null ) {
            return;
        }

        for ( final PageInfo page : _pages ) {
            for ( final TextureInfo[][] textures : page.textures ) {
                final int n = textures.length * textures[ 0 ].length;
                final int[] targets = new int[ n ];

                int index = 0;
                for ( final TextureInfo[] row : textures ) {
                    for ( final TextureInfo elem : row ) {
                        targets[ index++ ] = elem.id;
                    }
                }

                GLES10.glDeleteTextures( n , targets , 0 );
            }
        }
    }

    private void drawBackground() {
        drawSingleImage( _background.id , 0 , 0 , _background.width , _background.height );
    }

    private void drawImage( final CoreImageMatrix matrix , final SizeFInfo padding , final CoreImageState state ) {
        final int xSign = state.direction.toXSign();
        final int ySign = state.direction.toYSign();

        for ( int level = state.minLevel ; level <= state.maxLevel ; level++ ) {
            if ( level > state.minLevel && ( matrix.scale < Math.pow( 2 , level - state.minLevel - 1 ) || state.isCleanup() ) ) {
                // TODO consider to remove isCleanup
                // if ( level > state.minLevel && matrix.scale < Math.pow( 2 , level - state.minLevel - 1 ) ) {
                break;
            }

            float factor;

            if ( level != state.image.maxLevel || !state.image.isUseActualSize ) {
                factor = ( float ) Math.pow( 2 , level - state.minLevel );
            } else {
                factor =
                        level != state.minLevel ? 1f * state.image.width / ( RemoteProvider.TEXTURE_SIZE * ( float ) Math.pow( 2 , state.minLevel ) )
                                : 1f;
            }

            for ( int delta = -1 ; delta <= 1 ; delta++ ) {
                final int page = state.page + delta;

                final Point margin = margin( matrix , state , page , delta );

                if ( page >= 0 && page < _pages.length ) {
                    final TextureInfo[][] textures = _pages[ page ].textures[ level - state.minLevel ];
                    final PageTextureStatus[][] statuses = _pages[ page ].statuses[ level - state.minLevel ];

                    // -1 for rounding error
                    int y =
                            Math.round( state.surfaceSize.height
                                    - ( matrix.y( 0 ) + padding.height + matrix.length( state.pageSize.height - 1 ) * delta * ySign ) );

                    y += margin.y;

                    for ( int py = 0 ; py < textures.length ; py++ ) {
                        final int height = Math.round( matrix.length( textures[ py ][ 0 ].height ) / factor );

                        y -= height;

                        // -1 for rounding error
                        int x = Math.round( matrix.x( 0 ) + padding.width + matrix.length( state.pageSize.width - 1 ) * delta * xSign );

                        x += margin.x;

                        for ( int px = 0 ; px < textures[ py ].length ; px++ ) {
                            final int width = Math.round( matrix.length( textures[ py ][ px ].width ) / factor );

                            checkAndDrawSingleImage( level == state.minLevel , textures , statuses , py , px , x , y , width , height ,
                                    state.surfaceSize );

                            x += width;
                        }
                    }
                }
            }
        }
    }

    private void drawOverlay( final CoreImageMatrix matrix , final SizeFInfo padding , final CoreImageState state ,
            final List< CoreImageHighlight > highlights ) {
        final Point margin = margin( matrix , state , state.page , 0 );

        final float x = matrix.x( 0 ) + padding.width + margin.x;
        final float width = matrix.length( state.pageSize.width );
        final float y = state.surfaceSize.height - ( matrix.y( 0 ) + padding.height ) + margin.y;
        final float height = matrix.length( state.pageSize.height );

        for ( final CoreImageHighlight h : highlights ) {
            drawSingleImage( _red.id , Math.round( x + h.x * width ) , Math.round( y - ( h.y + h.h ) * height ) , Math.round( h.w * width ) ,
                    Math.round( h.h * height ) );
        }
    }

    private void drawSingleImage( final int id , final int x , final int y , final int w , final int h ) {
        GLES10.glBindTexture( GLES10.GL_TEXTURE_2D , id );
        GLES11Ext.glDrawTexiOES( x , y , 0 , w , h );
    }

    /**
     * @return [level][npx,npy]
     */
    int[][] getTextureDimension( final int page ) {
        final TextureInfo[][][] info = _pages[ page ].textures;

        final int[][] ret = new int[ _pages[ page ].textures.length ][];

        for ( int level = 0 ; level < info.length ; level++ ) {
            ret[ level ] = new int[] { info[ level ][ 0 ].length , info[ level ].length };
        }

        return ret;
    }

    private Point margin( final CoreImageMatrix matrix , final CoreImageState state , final int page , final int deltaPage ) {
        final int xSign = state.direction.toXSign();
        final int ySign = state.direction.toYSign();

        final Point deltaPoint = new Point();

        float marginTop = 0;
        float marginBottom = 0;
        float marginLeft = 0;
        float marginRight = 0;

        if ( state.spreadFirstPages.contains( page ) ) {
            marginRight = PAGE_MARGIN;
            marginTop = PAGE_MARGIN;
        } else if ( page - 1 >= 0 && state.spreadFirstPages.contains( page - 1 ) ) {
            marginLeft = PAGE_MARGIN;
            marginBottom = PAGE_MARGIN;
        } else {
            marginTop = marginBottom = marginLeft = marginRight = PAGE_MARGIN;
        }

        if ( deltaPage == -1 ) {
            deltaPoint.x += matrix.length( marginLeft ) * xSign * deltaPage;
        } else if ( deltaPage == 1 ) {
            deltaPoint.x += matrix.length( marginRight ) * xSign * deltaPage;
        }

        if ( deltaPage == -1 ) {
            deltaPoint.y -= matrix.length( marginBottom ) * deltaPage * ySign;
        } else if ( deltaPage == 1 ) {
            deltaPoint.y -= matrix.length( marginTop ) * deltaPage * ySign;
        }

        return deltaPoint;
    }

    private native void nativeUnload( int pointer );

    void prepare( final Context context , final int pages , final int minLevel , final int maxLevel , final SizeInfo pageSize ,
            final SizeInfo surfaceSize , final ImageInfo image ) {
        _background = TextureInfo.getTiledBitmapInstance( context.getResources() , R.drawable.background , surfaceSize );
        _blank = TextureInfo.getColorInstance( Color.WHITE );
        _red = TextureInfo.getColorInstance( Color.argb( 0x66 , 0xff , 0x00 , 0x00 ) );

        _pages = new PageInfo[ pages ];
        for ( int page = 0 ; page < _pages.length ; page++ ) {
            _pages[ page ] = new PageInfo( minLevel , maxLevel , pageSize , image );
        }
    }

    void render( final CoreImageState state ) {
        // copy for thread consistency
        _immutableMatrix.copy( state.matrix );
        _immutablePadding.width = state.getHorizontalPadding();
        _immutablePadding.height = state.getVerticalPadding();

        GLES10.glClear( GLES10.GL_COLOR_BUFFER_BIT );

        drawBackground();

        final long t = SystemClock.elapsedRealtime();

        drawImage( _immutableMatrix , _immutablePadding , state );

        _frameSum += SystemClock.elapsedRealtime() - t;

        drawOverlay( _immutableMatrix , _immutablePadding , state , Lists.newArrayList( state.highlights ) );

        _fpsCounter++;
        if ( _fpsCounter == 120 ) {
            // System.err.println( "drawImage FPS: " + 120.0 * 1000
            // / ( SystemClock.elapsedRealtime() - _fpsTime ) + ", avg: " + _frameSum / 120.0 );

            _fpsTime = SystemClock.elapsedRealtime();
            _fpsCounter = 0;
            _frameSum = 0;
        }
    }

    void unbindPageImage( final UnbindQueueItem item , final int minLevel ) {
        _pages[ item.page ].statuses[ item.level - minLevel ][ item.py ][ item.px ] = PageTextureStatus.UNBIND;

        GLES10.glDeleteTextures( 1 , new int[] { _pages[ item.page ].textures[ item.level - minLevel ][ item.py ][ item.px ].id } , 0 );
    }
}
