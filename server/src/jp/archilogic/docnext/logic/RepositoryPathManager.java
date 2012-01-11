package jp.archilogic.docnext.logic;

import jp.archilogic.docnext.bean.PropBean;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class RepositoryPathManager {
    @Autowired
    private PropBean prop;

    public String getDocumentRootDirPath() {
        return String.format( "%s/public/document/" , prop.repository );
    }

    public String getImageAnnotationPath( final long id , final int page ) {
        return String.format( "%s%d.anno.json" , getImageDirPath( id ) , page );
    }

    public String getImageDirPath( final long id ) {
        return String.format( "%s/public/document/%d/image/" , prop.repository , id );
    }

    public String getImageJsonPath( final long id ) {
        return String.format( "%simage.json" , getImageDirPath( id ) );
    }

    public String getImagePath( final long id , final int page , final int level , final int px , final int py , final boolean isWebp ) {
        return String.format( "%stexture-%d-%d-%d-%d.%s" , getImageDirPath( id ) , page , level , px , py , isWebp ? "webp" : "jpg" );
    }

    public String getImageTextIndexPath( final long id ) {
        return String.format( "%stext.index.zip" , getImageDirPath( id ) );
    }

    public String getImageTextRegionsPath( final long id , final int page ) {
        return String.format( "%s%d.regions" , getImageDirPath( id ) , page );
    }

    public String getInfoJsonPath( final long id ) {
        return String.format( "%s/public/document/%d/info.json" , prop.repository , id );
    }

    public String getRawPath( final long id ) {
        return String.format( "%s/private/raw/%d" , prop.repository , id );
    }

    public String getThumbnailPath( final long id , final int page ) {
        return String.format( "%sthumbnail-%d.jpg" , getImageDirPath( id ) , page );
    }
}
