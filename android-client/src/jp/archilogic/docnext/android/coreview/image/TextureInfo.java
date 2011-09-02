package jp.archilogic.docnext.android.coreview.image;

import jp.archilogic.docnext.android.info.SizeInfo;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.opengl.GLES10;
import android.opengl.GLES11;
import android.opengl.GLES11Ext;
import android.opengl.GLUtils;

public class TextureInfo {
    static {
        System.loadLibrary( "NativeWebp" );
    }

    public static TextureInfo getColorInstance( final int color ) {
        final Bitmap bitmap = Bitmap.createBitmap( 1 , 1 , Config.ARGB_8888 );

        new Canvas( bitmap ).drawColor( color );

        return new TextureInfo( bitmap , bitmap.getWidth() , bitmap.getHeight() );
    }

    private static int getTextureSize( final int width , final int height ) {
        final int value = Math.max( width , height );

        for ( int size = 1 ; ; size <<= 1 ) {
            if ( size >= value ) {
                return size;
            }
        }
    }

    public static TextureInfo getTiledBitmapInstance( final Resources res , final int resId , final SizeInfo size ) {
        final Bitmap source = BitmapFactory.decodeResource( res , resId );

        final int len = getTextureSize( size.width , size.height );
        final Bitmap bitmap = Bitmap.createBitmap( len , len , Config.RGB_565 );

        final Canvas c = new Canvas( bitmap );
        final Paint p = new Paint();

        for ( int y = 0 ; y * source.getHeight() < size.height ; y++ ) {
            for ( int x = 0 ; x * source.getWidth() < size.width ; x++ ) {
                c.drawBitmap( source , x * source.getWidth() , y * source.getHeight() , p );
            }
        }

        source.recycle();

        return new TextureInfo( bitmap , size.width , size.height );
    }

    public int id;
    public int width;
    public int height;

    protected TextureInfo( final Bitmap bitmap , final int width , final int height ) {
        this( width , height );

        bindTexture( bitmap );
        bitmap.recycle();
    }

    protected TextureInfo( final int width , final int height ) {
        this.width = width;
        this.height = height;

        genTexture();
    }

    /**
     * Crop is keeping left and top edge
     */
    public void bindTexture( final Bitmap bitmap ) {
        GLES10.glBindTexture( GLES10.GL_TEXTURE_2D , id );

        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_MIN_FILTER , GLES10.GL_LINEAR );
        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_MAG_FILTER , GLES10.GL_LINEAR );

        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_WRAP_S , GLES10.GL_CLAMP_TO_EDGE );
        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_WRAP_T , GLES10.GL_CLAMP_TO_EDGE );

        GLUtils.texImage2D( GLES10.GL_TEXTURE_2D , 0 , bitmap , 0 );

        GLES11.glTexParameteriv( GLES10.GL_TEXTURE_2D , GLES11Ext.GL_TEXTURE_CROP_RECT_OES , //
                new int[] { 0 , height , width , -height } , 0 );
    }

    public void bindTexture( final int pointer ) {
        GLES10.glBindTexture( GLES10.GL_TEXTURE_2D , id );

        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_MIN_FILTER , GLES10.GL_LINEAR );
        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_MAG_FILTER , GLES10.GL_LINEAR );

        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_WRAP_S , GLES10.GL_CLAMP_TO_EDGE );
        GLES10.glTexParameterf( GLES10.GL_TEXTURE_2D , GLES10.GL_TEXTURE_WRAP_T , GLES10.GL_CLAMP_TO_EDGE );

        nativeTexImage2D( id , pointer , RemoteProvider.TEXTURE_SIZE , RemoteProvider.TEXTURE_SIZE );

        GLES11.glTexParameteriv( GLES10.GL_TEXTURE_2D , GLES11Ext.GL_TEXTURE_CROP_RECT_OES , //
                new int[] { 0 , height , width , -height } , 0 );
    }

    protected void genTexture() {
        final int[] texture = new int[ 1 ];

        GLES10.glGenTextures( 1 , texture , 0 );

        this.id = texture[ 0 ];
    }

    private native void nativeTexImage2D( int id , int pointer , int width , int height );
}
