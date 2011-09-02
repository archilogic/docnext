package jp.archilogic.docnext.android.provider.remote;

import java.util.List;

import jp.archilogic.docnext.android.task.ConcatDownloadTask;
import jp.archilogic.docnext.android.task.DownloadTask;
import jp.archilogic.docnext.android.task.Receiver;
import android.content.Context;

/**
 * @@ Download process is handled by root activity (or service?)
 * @@ Notify process finishing is archived through BroadCast
 */
public interface RemoteProvider {
    int TEXTURE_SIZE = 512;

    DownloadTask getImageInfo( Context context , Receiver< Void > receiver , String endpoint , String localDir );

    DownloadTask getImageRegions( Context context , Receiver< Void > receiver , String endpoint , String localDir , int page );

    ConcatDownloadTask getImageRegionsAll( Context context , Receiver< Void > receiver , String endpoint , String localDir , List< String > names );

    DownloadTask getImageTextIndex( Context context , Receiver< Void > receiver , String endpoint , String localDir );

    DownloadTask getImageTexture( Context context , Receiver< Void > receiver , String endpoint , String localDir , int page , int level , int px ,
            int py , boolean isWebp );

    ConcatDownloadTask getImageTexturePerPage( Context context , Receiver< Void > receiver , String endpoint , String localDir , List< String > names );

    DownloadTask getImageThumbnail( Context context , Receiver< Void > receiver , String endpoint , String localDir , int page );

    ConcatDownloadTask getImageThumbnailAll( Context context , Receiver< Void > receiver , String endpoint , String localDir , List< String > names );

    DownloadTask getInfo( Context context , Receiver< Void > receiver , String endpoint , String localDir );
}
