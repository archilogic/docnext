package jp.archilogic.docnext.android.coreview.image;

import jp.archilogic.docnext.android.info.ImageInfo;
import jp.archilogic.docnext.android.info.SizeInfo;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;

public class PageInfo {
    public enum PageTextureStatus {
        UNBIND , BIND;
    }

    public TextureInfo[][][] textures;
    public PageTextureStatus[][][] statuses;

    public PageInfo( final int minLevel , final int maxLevel , final SizeInfo page , final ImageInfo image ) {
        textures = new TextureInfo[ maxLevel - minLevel + 1 ][][];
        statuses = new PageTextureStatus[ maxLevel - minLevel + 1 ][][];
        for ( int level = minLevel ; level <= maxLevel - ( maxLevel == image.maxLevel && image.isUseActualSize ? 1 : 0 ) ; level++ ) {
            final int factor = ( int ) Math.pow( 2 , level - minLevel );
            final int nx = ( page.width * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            final int ny = ( page.height * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            textures[ level - minLevel ] = new TextureInfo[ ny ][ nx ];
            statuses[ level - minLevel ] = new PageTextureStatus[ ny ][ nx ];

            for ( int py = 0 ; py < ny ; py++ ) {
                for ( int px = 0 ; px < nx ; px++ ) {
                    final int x = px * RemoteProvider.TEXTURE_SIZE;
                    final int y = py * RemoteProvider.TEXTURE_SIZE;

                    textures[ level - minLevel ][ py ][ px ] =
                            new TextureInfo( Math.min( page.width * factor - x , RemoteProvider.TEXTURE_SIZE ) , Math.min( page.height * factor - y ,
                                    RemoteProvider.TEXTURE_SIZE ) );
                    statuses[ level - minLevel ][ py ][ px ] = PageTextureStatus.UNBIND;
                }
            }
        }

        if ( maxLevel == image.maxLevel && image.isUseActualSize ) {
            final int nx = ( image.width - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            final int ny = ( image.height - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            textures[ maxLevel - minLevel ] = new TextureInfo[ ny ][ nx ];
            statuses[ maxLevel - minLevel ] = new PageTextureStatus[ ny ][ nx ];

            for ( int py = 0 ; py < ny ; py++ ) {
                for ( int px = 0 ; px < nx ; px++ ) {
                    final int x = px * RemoteProvider.TEXTURE_SIZE;
                    final int y = py * RemoteProvider.TEXTURE_SIZE;

                    textures[ maxLevel - minLevel ][ py ][ px ] =
                            new TextureInfo( Math.min( image.width - x , RemoteProvider.TEXTURE_SIZE ) , Math.min( image.height - y ,
                                    RemoteProvider.TEXTURE_SIZE ) );
                    statuses[ maxLevel - minLevel ][ py ][ px ] = PageTextureStatus.UNBIND;
                }
            }
        }
    }
}
