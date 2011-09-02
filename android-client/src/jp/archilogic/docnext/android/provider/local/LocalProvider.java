package jp.archilogic.docnext.android.provider.local;

import java.util.Collection;
import java.util.List;

import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.BookmarkInfo;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.info.DownloadInfo;
import jp.archilogic.docnext.android.info.ImageInfo;
import net.arnx.jsonic.JSONException;
import android.content.res.Resources;
import android.graphics.RectF;

/**
 * This interface may be change (for requested feature)
 */
public interface LocalProvider {
    void cleanupImageTextIndex() throws NoMediaMountException;

    /**
     * @return null if not exists
     * @throws NoMediaMountException
     */
    List< BookmarkInfo > getBookmarkInfo( String localDir ) throws NoMediaMountException , JSONException;

    /**
     * @return null if not exists
     */
    DownloadInfo getDownloadInfo() throws JSONException , NoMediaMountException;

    /**
     * @return null if not exists
     * @throws NoMediaMountException
     *             , Exception
     */
    ImageInfo getImageInfo( String localDir ) throws NoMediaMountException , JSONException;

    List< RectF > getImageRegions( String localDir , int page ) throws NoMediaMountException;

    /**
     * @return null if not exists
     */
    String getImageTexturePath( String localDir , int page , int level , int px , int py , boolean isWebp ) throws NoMediaMountException;

    /**
     * @return null if not exists
     */
    String getImageThumbnailPath( String localDir , int page ) throws NoMediaMountException;

    /**
     * @return null if not exists
     * @throws NoMediaMountException
     */
    DocInfo getInfo( String localDir ) throws NoMediaMountException , JSONException;

    /**
     * @return null if not exists
     */
    int getLastOpenedPage( String localDir ) throws NoMediaMountException;

    Collection< Integer > getSpreadFirstPages( String localDir ) throws NoMediaMountException , JSONException;

    String getTOCText( String localDir , int page ) throws NoMediaMountException , JSONException;

    boolean isAllImageExists( String localDir , int page , Resources res ) throws NoMediaMountException , JSONException;

    boolean isCompleted( String localDir ) throws NoMediaMountException;

    boolean isImageExists( String localDir , int page , int level , int px , int py , boolean isWebp ) throws NoMediaMountException;

    boolean isImageInitDownloaded( String localDir ) throws NoMediaMountException;

    boolean isImageTextIndexExists( String localDir ) throws NoMediaMountException;

    void prepareImageTextIndex( String localDir ) throws NoMediaMountException;

    void setBookmarkInfo( String localDir , List< BookmarkInfo > bookmarks ) throws NoMediaMountException , JSONException;

    void setCompleted( String localDir ) throws NoMediaMountException;

    void setDownloadInfo( DownloadInfo info ) throws NoMediaMountException , JSONException;

    void setImageInitDownloaded( String localDir ) throws NoMediaMountException;

    void setLastOpenedPage( String localDir , int page ) throws NoMediaMountException;

    /**
     * for backward-compatibility
     */
    void updateImageInitDownloaded( String localDir ) throws NoMediaMountException;
}
