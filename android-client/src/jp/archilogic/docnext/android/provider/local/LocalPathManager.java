package jp.archilogic.docnext.android.provider.local;

import java.io.File;
import java.io.IOException;

import jp.archilogic.docnext.android.util.FileUtils2;
import android.os.Environment;

public class LocalPathManager {
    // take care this var depends on package name :(
    //private final String ROOT = Environment.getDataDirectory() + "/data/jp.archilogic.docnext.android.mock/files/";
    private final String ROOT = "/sdcard/docnext";

    private void ensure( final String path ) {
        final File dir = new File( path );

        if ( !dir.exists() ) {
            dir.mkdirs();
        }
    }

    public void ensureDocumentDir( final String localDir ) {
        try {
            ensure( localDir );

            FileUtils2.touch( new File( localDir , ".nomedia" ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public void ensureImageDir( final String localDir ) {
        try {
            ensure( getImageDir( localDir ) );

            FileUtils2.touch( new File( getImageDir( localDir ) , ".nomedia" ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    public void ensureRoot() {
        ensure( ROOT );
    }
    
    public String getAnnotationPath( final String localDir, final int page ) {
        return String.format( "%s%d.annon.json" , localDir, page );
    }
    
    public String getBookmarkPath( final String localDir ) {
        return String.format( "%sbookmark.json" , localDir );
    }

    public String getCompletedInfoPath( final String localDir ) {
        return String.format( "%scompleted" , localDir );
    }

    public String getDownloadInfoPath() {
        return String.format( "%sdownload.info.json" , ROOT );
    }

    public String getImageDir( final String localDir ) {
        return String.format( "%simage/" , localDir );
    }

    public String getImageInfoPath( final String localDir ) {
        return String.format( "%simage.json" , getImageDir( localDir ) );
    }

    public String getImageInitDownloadedInfoPath( final String localDir ) {
        return String.format( "%simage_init_downloaded" , localDir );
    }

    public String getImageRegionsName( final int page ) {
        return String.format( "%d.regions" , page );
    }

    public String getImageRegionsPath( final String localDir , final int page ) {
        return getImageDir( localDir ) + getImageRegionsName( page );
    }

    public String getImageTextIndexPath( final String localDir ) {
        return String.format( "%stext.index.zip" , getImageDir( localDir ) );
    }

    public String getImageTextureName( final int page , final int level , final int px , final int py , final boolean isWebp ) {
        return String.format( "texture-%d-%d-%d-%d.%s" , page , level , px , py , isWebp ? "webp" : "jpg" );
    }

    public String getImageTexturePath( final String localDir , final int page , final int level , final int px , final int py , final boolean isWebp ) {
        return getImageDir( localDir ) + getImageTextureName( page , level , px , py , isWebp );
    }

    public String getImageThumbnailName( final int page ) {
        return String.format( "thumbnail-%d.jpg" , page );
    }

    public String getImageThumbnailPath( final String localDir , final int page ) {
        return getImageDir( localDir ) + getImageThumbnailName( page );
    }

    public String getInfoPath( final String localDir ) {
        return String.format( "%sinfo.json" , localDir );
    }

    public String getLastOpenedPagePath( final String localDir ) {
        return String.format( "%slastOpenedPage.json" , localDir );
    }

    public String getWorkingDownloadPath() {
        return String.format( "%sdownload" , ROOT );
    }

    public String getWorkingImageTextIndexDirPath() {
        return String.format( "%stext.index/" , ROOT );
    }

    public String getWorkingImageTextIndexFilePath() {
        return String.format( "%stext.index.zip" , ROOT );
    }
}
