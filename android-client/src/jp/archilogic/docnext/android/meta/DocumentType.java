package jp.archilogic.docnext.android.meta;

import jp.archilogic.docnext.android.coreview.CoreView;
import jp.archilogic.docnext.android.coreview.image.CoreImageView;
import jp.archilogic.docnext.android.coreview.image.facingpages.CoreFacingImageView;
import jp.archilogic.docnext.android.coreview.image.facingpages.Device;
import jp.archilogic.docnext.android.coreview.thumbnail.ThumbnailView;
import jp.archilogic.docnext.android.type.FragmentType;
import android.content.Context;

public enum DocumentType {
    IMAGE , THUMBNAIL;

    public CoreView buildView( final Context context ) {
        switch ( this ) {
        case IMAGE:
            Device.init( context );
            if ( Device.getPageHelper() == 2 ) {
                return new CoreFacingImageView( context );
            } else {
                return new CoreImageView( context );
            }
        case THUMBNAIL:
            return new ThumbnailView( context );
        default:
            throw new RuntimeException( "assert" );
        }
    }

    public FragmentType[] getPrimarySwitchFragment() {
        switch ( this ) {
        case IMAGE:
            return new FragmentType[] { FragmentType.BOOKMARK , FragmentType.BOOKMARKLIST , FragmentType.THUMBNAIL };
        case THUMBNAIL:
            return new FragmentType[] { FragmentType.TOC , FragmentType.SETTING , FragmentType.BOOKMARKLIST };
        default:
            throw new RuntimeException( "assert" );
        }
    }

    public FragmentType[] getSecondarySwitchFragment() {
        switch ( this ) {
        case IMAGE:
            return new FragmentType[] { FragmentType.TOC };
        case THUMBNAIL:
            return new FragmentType[] {};
        default:
            throw new RuntimeException( "assert" );
        }
    }

    public FragmentType[] getSubSecondarySwitchFragment() {
        switch ( this ) {
        case IMAGE:
            return new FragmentType[] { FragmentType.SETTING , FragmentType.HOME };
        case THUMBNAIL:
            return new FragmentType[] {};
        default:
            throw new RuntimeException( "assert" );
        }
    }

    public boolean isRoot() {
        switch ( this ) {
        case IMAGE:
            return true;
        case THUMBNAIL:
            return false;
        default:
            throw new RuntimeException( "assert" );
        }
    }
}
