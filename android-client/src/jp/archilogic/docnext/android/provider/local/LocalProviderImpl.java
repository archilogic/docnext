package jp.archilogic.docnext.android.provider.local;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.DoubleBuffer;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.BookmarkInfo;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.info.DownloadInfo;
import jp.archilogic.docnext.android.info.ImageInfo;
import jp.archilogic.docnext.android.info.TOCElem;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import jp.archilogic.docnext.android.task.DownloadTask;
import jp.archilogic.docnext.android.util.CustomJSON;
import jp.archilogic.docnext.android.util.FileUtils2;
import jp.archilogic.docnext.android.util.ImageLevelUtil;
import net.arnx.jsonic.JSON;
import net.arnx.jsonic.JSONException;

import org.apache.commons.compress.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress.archivers.zip.ZipFile;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import android.content.res.Resources;
import android.graphics.RectF;
import android.os.Environment;

import com.google.common.collect.Lists;

public class LocalProviderImpl implements LocalProvider {
    private final LocalPathManager _pathManager = new LocalPathManager();

    @SuppressWarnings("rawtypes")
    @Override
    public Map[] annotation( final String localDir , final int page ) {
        try {
            Map[] map;

            if (!(new File(_pathManager.getAnnotationPath(localDir, page)).exists())) {
                return null;
            }

            map = getJsonInfo(_pathManager.getAnnotationPath(localDir, page), Map[].class);
            return map;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    
    private void checkMediaMount() throws NoMediaMountException {
        if ( !Environment.MEDIA_MOUNTED.equals( Environment.getExternalStorageState() ) ) {
            throw new NoMediaMountException();
        }
    }

    @Override
    public void cleanupImageTextIndex() throws NoMediaMountException {
        checkMediaMount();

        FileUtils.deleteQuietly( new File( _pathManager.getWorkingImageTextIndexFilePath() ) );
        try {
            FileUtils.deleteDirectory( new File( _pathManager.getWorkingImageTextIndexDirPath() ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    @Override
    public List< BookmarkInfo > getBookmarkInfo( final String localDir ) throws NoMediaMountException , JSONException {
        checkMediaMount();

        final BookmarkInfo[] bookmarks = getJsonInfo( _pathManager.getBookmarkPath( localDir ) , BookmarkInfo[].class );

        if ( bookmarks == null ) {
            return Lists.newArrayList();
        }

        for ( final BookmarkInfo bookmark : bookmarks ) {
            bookmark.text = getTOCText( localDir , bookmark.page );
        }

        return Lists.newArrayList( bookmarks );
    }

    @Override
    public DownloadInfo getDownloadInfo() throws NoMediaMountException , JSONException {
        return getJsonInfo( _pathManager.getDownloadInfoPath() , DownloadInfo.class );
    }

    @Override
    public ImageInfo getImageInfo( final String localDir ) throws NoMediaMountException , JSONException {
        return getJsonInfo( _pathManager.getImageInfoPath( localDir ) , ImageInfo.class );
    }

    @Override
    public List< RectF > getImageRegions( final String localDir , final int page ) throws NoMediaMountException {
        checkMediaMount();

        final File file = new File( _pathManager.getImageRegionsPath( localDir , page ) );

        if ( !file.exists() ) {
            return null;
        }

        final List< RectF > ret = Lists.newArrayList();

        ByteBuffer buf;
        try {
            buf = ByteBuffer.wrap( FileUtils.readFileToByteArray( file ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
        buf.order( ByteOrder.LITTLE_ENDIAN );

        final DoubleBuffer db = buf.asDoubleBuffer();
        while ( db.remaining() > 0 ) {
            final double x = db.get();
            final double y = db.get();
            final double w = db.get();
            final double h = db.get();

            ret.add( new RectF( ( float ) x , ( float ) y , ( float ) ( x + w ) , ( float ) ( y + h ) ) );
        }

        return ret;
    }

    @Override
    public String getImageTexturePath( final String localDir , final int page , final int level , final int px , final int py , final boolean isWebp )
            throws NoMediaMountException {
        checkMediaMount();

        final String ret = _pathManager.getImageTexturePath( localDir , page , level , px , py , isWebp );

        if ( !new File( ret ).exists() ) {
            return null;
        }

        return ret;
    }

    @Override
    public String getImageThumbnailPath( final String localDir , final int page ) throws NoMediaMountException {
        checkMediaMount();

        final String ret = _pathManager.getImageThumbnailPath( localDir , page );

        if ( !new File( ret ).exists() ) {
            return null;
        }

        return ret;
    }

    @Override
    public DocInfo getInfo( final String localDir ) throws NoMediaMountException , JSONException {
        return getJsonInfo( _pathManager.getInfoPath( localDir ) , DocInfo.class );
    }

    private < T > T getJsonInfo( final String path , final Class< ? extends T > cls ) throws NoMediaMountException , JSONException {
        checkMediaMount();

        final File f = new File( path );

        if ( !f.exists() ) {
            return null;
        }

        String json;
        try {
            json = FileUtils.readFileToString( f );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }

        JSON.prototype = CustomJSON.class;

        return JSON.decode( json , cls );
    }

    @Override
    public int getLastOpenedPage( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        try {
            return Integer.valueOf( FileUtils.readFileToString( new File( _pathManager.getLastOpenedPagePath( localDir ) ) ).trim() );
        } catch ( final Exception e ) {
            return -1;
        }
    }

    @Override
    public Collection< Integer > getSpreadFirstPages( final String localDir ) throws NoMediaMountException , JSONException {
        final Collection< Integer > ret = new HashSet< Integer >();

        final DocInfo doc = getInfo( localDir );
        final List< Integer > singlePages = doc.singlePages;
        for ( int page = 0 ; page < doc.pages ; page++ ) {
            if ( !singlePages.contains( page ) && ( page == 0 || !ret.contains( page - 1 ) ) && page != doc.pages - 1 ) {
                ret.add( page );
            }
        }

        return ret;
    }

    @Override
    public String getTOCText( final String localDir , final int page ) throws NoMediaMountException , JSONException {
        String ret = "NO TITLE";

        for ( final TOCElem toc : getInfo( localDir ).toc ) {
            if ( toc.page > page ) {
                return ret;
            }

            if ( toc.page <= page ) {
                ret = toc.text;
            }
        }

        return ret;
    }

    @Override
    public boolean isAllImageExists( final String localDir , final int page , final Resources res ) throws NoMediaMountException , JSONException {
        final ImageInfo image = getImageInfo( localDir );

        final int minLevel = ImageLevelUtil.getMinLevel( res , image.maxLevel );

        final int width =
                minLevel != image.maxLevel || !image.isUseActualSize ? ( int ) ( RemoteProvider.TEXTURE_SIZE * Math.pow( 2 , minLevel ) )
                        : image.width;
        final int height = image.height * width / image.width;

        final int nx = ( width - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
        final int ny = ( height - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;

        for ( int py = 0 ; py < ny ; py++ ) {
            for ( int px = 0 ; px < nx ; px++ ) {
                if ( getImageTexturePath( localDir , page , minLevel , px , py , image.isWebp ) == null ) {
                    return false;
                }
            }
        }

        return true;
    }

    @Override
    public boolean isCompleted( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        return new File( _pathManager.getCompletedInfoPath( localDir ) ).exists();
    }

    @Override
    public boolean isImageExists( final String localDir , final int page , final int level , final int px , final int py , final boolean isWebp )
            throws NoMediaMountException {
        final String path = getImageTexturePath( localDir , page , level , px , py , isWebp );

        return path != null && !new File( path + DownloadTask.DOWNLOADING_POSTFIX ).exists();
    }

    @Override
    public boolean isImageInitDownloaded( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        return new File( _pathManager.getImageInitDownloadedInfoPath( localDir ) ).exists();
    }

    @Override
    public boolean isImageTextIndexExists( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        return new File( _pathManager.getImageTextIndexPath( localDir ) ).exists();
    }

    @Override
    public void prepareImageTextIndex( final String localDir ) throws NoMediaMountException {
        unzip( _pathManager.getImageTextIndexPath( localDir ) , _pathManager.getWorkingImageTextIndexFilePath() ,
                _pathManager.getWorkingImageTextIndexDirPath() );
    }

    @Override
    public void setBookmarkInfo( final String localDir , final List< BookmarkInfo > bookmarks ) throws NoMediaMountException , JSONException {
        setJsonInfo( _pathManager.getBookmarkPath( localDir ) , bookmarks );
    }

    @Override
    public void setCompleted( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        try {
            FileUtils2.touch( new File( _pathManager.getCompletedInfoPath( localDir ) ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    @Override
    public void setDownloadInfo( final DownloadInfo info ) throws NoMediaMountException , JSONException {
        if ( info != null ) {
            setJsonInfo( _pathManager.getDownloadInfoPath() , info );
        } else {
            FileUtils.deleteQuietly( new File( _pathManager.getDownloadInfoPath() ) );
        }
    }

    @Override
    public void setImageInitDownloaded( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        try {
            FileUtils2.touch( new File( _pathManager.getImageInitDownloadedInfoPath( localDir ) ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private void setJsonInfo( final String path , final Object source ) throws NoMediaMountException , JSONException {
        checkMediaMount();

        OutputStream out = null;
        try {
            out = FileUtils.openOutputStream( new File( path ) );

            JSON.prototype = CustomJSON.class;

            JSON.encode( source , out );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } finally {
            IOUtils.closeQuietly( out );
        }
    }

    @Override
    public void setLastOpenedPage( final String localDir , final int page ) throws NoMediaMountException {
        checkMediaMount();

        try {
            FileUtils.writeStringToFile( new File( _pathManager.getLastOpenedPagePath( localDir ) ) , Integer.toString( page ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private void unzip( final String srcPath , final String workingFilePath , final String workingDirPath ) throws NoMediaMountException {
        checkMediaMount();

        try {
            _pathManager.ensureRoot();

            FileUtils.copyFile( new File( srcPath ) , new File( workingFilePath ) );

            final File dst = new File( workingDirPath );
            ZipFile zip;
            try {
                zip = new ZipFile( workingFilePath );
            } catch ( final IOException e ) {
                throw new RuntimeException( e );
            }

            if ( dst.exists() ) {
                cleanupImageTextIndex();
            }

            @SuppressWarnings( "unchecked" )
            final Enumeration< ZipArchiveEntry > entries = zip.getEntries();
            while ( entries.hasMoreElements() ) {
                final ZipArchiveEntry entry = entries.nextElement();

                final File out = new File( dst , entry.getName() );

                if ( entry.isDirectory() ) {
                    out.mkdirs();
                } else {
                    final OutputStream os = FileUtils.openOutputStream( out );
                    IOUtils.copy( zip.getInputStream( entry ) , os );
                    IOUtils.closeQuietly( os );
                }
            }
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    /**
     * for backward-compatibility
     */
    @Override
    public void updateImageInitDownloaded( final String localDir ) throws NoMediaMountException {
        checkMediaMount();

        final String old = String.format( "%sinit_downloaded" , localDir );

        if ( new File( old ).exists() ) {
            try {
                FileUtils.moveFile( new File( old ) , new File( _pathManager.getImageInitDownloadedInfoPath( localDir ) ) );
            } catch ( final IOException e ) {
                throw new RuntimeException( e );
            }
        }
    }
}
