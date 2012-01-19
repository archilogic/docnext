package jp.archilogic.docnext.android.provider.remote;

public interface RemotePathManager {
    String getAnnotationPath( String endpoint , int page );
	  
    String getImageDir( String endpoint );

    String getImageInfoPath( String endpoint );

    String getImageRegionsPath( String endpoint , int page );

    String getImageTextIndexPath( String endpoint );

    String getImageTexturePath( String endpoint , int page , int level , int px , int py , boolean isWebp );

    String getImageThumbnailPath( String endpoint , int page );

    String getInfoPath( String endpoint );
}
