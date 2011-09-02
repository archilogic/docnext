package jp.archilogic.docnext.android.type;

import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.meta.DocumentType;
import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public enum FragmentType {
    HOME , IMAGE , TOC , BOOKMARK , THUMBNAIL , SETTING , SEARCH , BOOKMARKLIST;

    public View buildButton( final Context context ) {
        final LinearLayout root = new LinearLayout( context );
        root.setLayoutParams( new LinearLayout.LayoutParams( 0 , LinearLayout.LayoutParams.WRAP_CONTENT , 1 ) );
        root.setOrientation( LinearLayout.VERTICAL );
        root.setGravity( Gravity.CENTER_HORIZONTAL );

        final ImageView image = new ImageView( context );
        image.setId( R.id.menu_item_image );
        image.setImageResource( getImageResouce() );
        root.addView( image );

        final TextView text = new TextView( context );
        text.setGravity( Gravity.CENTER_HORIZONTAL );
        text.setText( getTextResource() );
        text.setTextColor( Color.WHITE );
        root.addView( text );

        return root;
    }

    public DocumentType getDocumentType() {
        switch ( this ) {
        case IMAGE:
            return DocumentType.IMAGE;
        case THUMBNAIL:
            return DocumentType.THUMBNAIL;
        case TOC:
        case BOOKMARKLIST:
        case HOME:
        case SETTING:
        case SEARCH:
        case BOOKMARK:
            return null;
        default:
            throw new RuntimeException( "assert" );
        }
    }

    private int getImageResouce() {
        switch ( this ) {
        case HOME:
            return R.drawable.button_home;
        case IMAGE:
            return R.drawable.button_image;
        case TOC:
            return R.drawable.button_toc;
        case BOOKMARK:
            return R.drawable.button_bookmark_off;
        case BOOKMARKLIST:
            return R.drawable.button_bookmarklist;
        case THUMBNAIL:
            return R.drawable.button_thumbnail;
        case SETTING:
            return R.drawable.button_setting;
        case SEARCH:
            return R.drawable.button_search;
        default:
            throw new RuntimeException( "assert" );
        }
    }

    private int getTextResource() {
        switch ( this ) {
        case HOME:
            return R.string.home;
        case IMAGE:
            return R.string.image;
        case TOC:
            return R.string.toc;
        case BOOKMARK:
            return R.string.bookmark;
        case THUMBNAIL:
            return R.string.thumbnail;
        case SETTING:
            return R.string.setting;
        case SEARCH:
            return R.string.search;
        case BOOKMARKLIST:
            return R.string.bookmark_list;
        default:
            throw new RuntimeException( "assert" );
        }
    }
}
