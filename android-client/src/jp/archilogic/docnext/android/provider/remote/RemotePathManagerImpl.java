package jp.archilogic.docnext.android.provider.remote;

public class RemotePathManagerImpl implements RemotePathManager {
    @Override
    public String getImageDir( final String endpoint ) {
        return String.format( "%simage/" , endpoint );
    }

    @Override
    public String getImageInfoPath( final String endpoint ) {
        return String.format( "%simage.json" , getImageDir( endpoint ) );
    }

    @Override
    public String getImageRegionsPath( final String endpoint , final int page ) {
        return String.format( "%s%d.regions" , getImageDir( endpoint ) , page );
    }

    @Override
    public String getImageTextIndexPath( final String endpoint ) {
        return String.format( "%stext.index.zip" , getImageDir( endpoint ) );
    }

    @Override
    public String getImageTexturePath( final String endpoint , final int page , final int level , final int px , final int py , final boolean isWebp ) {
        return String.format( "%stexture-%d-%d-%d-%d.%s" , getImageDir( endpoint ) , page , level , px , py , isWebp ? "webp" : "jpg" );
    }

    @Override
    public String getImageThumbnailPath( final String endpoint , final int page ) {
        return String.format( "%sthumbnail-%d.jpg" , getImageDir( endpoint ) , page );
    }

    @Override
    public String getInfoPath( final String endpoint ) {
        return String.format( "%sinfo.json" , endpoint );
    }
}
