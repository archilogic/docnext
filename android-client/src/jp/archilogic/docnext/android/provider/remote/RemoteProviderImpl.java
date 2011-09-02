package jp.archilogic.docnext.android.provider.remote;

import java.util.List;

import jp.archilogic.docnext.android.provider.local.LocalPathManager;
import jp.archilogic.docnext.android.task.ConcatDownloadTask;
import jp.archilogic.docnext.android.task.DownloadTask;
import jp.archilogic.docnext.android.task.Receiver;
import android.content.Context;

public class RemoteProviderImpl implements RemoteProvider {
    private final RemotePathManager _remotePathManager = new RemotePathManagerImpl();
    private final LocalPathManager _localPathManager = new LocalPathManager();

    private ConcatDownloadTask getImageContents( final Context context , final Receiver< Void > receiver , final String endpoint ,
            final String localDir , final List< String > names ) {
        _localPathManager.ensureImageDir( localDir );

        return new ConcatDownloadTask( context , receiver , _remotePathManager.getImageDir( endpoint ) , names ,
                _localPathManager.getImageDir( localDir ) , names );
    }

    @Override
    public DownloadTask getImageInfo( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ) {
        _localPathManager.ensureImageDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getImageInfoPath( endpoint ) , _localPathManager.getImageInfoPath( localDir ) );
    }

    @Override
    public DownloadTask getImageRegions( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ,
            final int page ) {
        _localPathManager.ensureImageDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getImageRegionsPath( endpoint , page ) ,
                _localPathManager.getImageRegionsPath( localDir , page ) );
    }

    @Override
    public ConcatDownloadTask getImageRegionsAll( final Context context , final Receiver< Void > receiver , final String endpoint ,
            final String localDir , final List< String > names ) {
        return getImageContents( context , receiver , endpoint , localDir , names );
    }

    @Override
    public DownloadTask getImageTextIndex( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ) {
        _localPathManager.ensureImageDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getImageTextIndexPath( endpoint ) ,
                _localPathManager.getImageTextIndexPath( localDir ) );
    }

    @Override
    public DownloadTask getImageTexture( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ,
            final int page , final int level , final int px , final int py , final boolean isWebp ) {
        _localPathManager.ensureImageDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getImageTexturePath( endpoint , page , level , px , py , isWebp ) ,
                _localPathManager.getImageTexturePath( localDir , page , level , px , py , isWebp ) );
    }

    @Override
    public ConcatDownloadTask getImageTexturePerPage( final Context context , final Receiver< Void > receiver , final String endpoint ,
            final String localDir , final List< String > names ) {
        return getImageContents( context , receiver , endpoint , localDir , names );
    }

    @Override
    public DownloadTask getImageThumbnail( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ,
            final int page ) {
        _localPathManager.ensureImageDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getImageThumbnailPath( endpoint , page ) ,
                _localPathManager.getImageThumbnailPath( localDir , page ) );
    }

    @Override
    public ConcatDownloadTask getImageThumbnailAll( final Context context , final Receiver< Void > receiver , final String endpoint ,
            final String localDir , final List< String > names ) {
        return getImageContents( context , receiver , endpoint , localDir , names );
    }

    @Override
    public DownloadTask getInfo( final Context context , final Receiver< Void > receiver , final String endpoint , final String localDir ) {
        _localPathManager.ensureDocumentDir( localDir );

        return new DownloadTask( context , receiver , _remotePathManager.getInfoPath( endpoint ) , _localPathManager.getInfoPath( localDir ) );
    }
}
