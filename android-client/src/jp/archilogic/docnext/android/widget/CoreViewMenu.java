package jp.archilogic.docnext.android.widget;

import java.util.List;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.activity.bookmark.BookmarkActivity;
import jp.archilogic.docnext.android.activity.toc.TOCActivity;
import jp.archilogic.docnext.android.coreview.CoreView;
import jp.archilogic.docnext.android.coreview.HasPage;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.BookmarkInfo;
import jp.archilogic.docnext.android.meta.DocumentType;
import jp.archilogic.docnext.android.setting.SettingActivity;
import jp.archilogic.docnext.android.type.FragmentType;
import net.arnx.jsonic.JSONException;
import android.app.Activity;
import android.content.Intent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public class CoreViewMenu extends LinearLayout {
    public interface CoreViewMenuDelegate {
        void changeCoreViewType( DocumentType type , Intent extra );

        CoreView getCoreView();

        void goBack();
    }

    private final String _localDir;
    private final CoreViewMenuDelegate _delegate;
    private final Activity _activity;

    private View _bookmarkMenuItem;
    private TextView _titleView;

    public CoreViewMenu( final Activity activity , final String localDir , final CoreViewMenuDelegate delegate ) {
        super( activity );

        _localDir = localDir;
        _delegate = delegate;
        _activity = activity;

        initialize();
    }

    private void bindBookmarkMenuItemIcon() {
        if ( !( _delegate.getCoreView() instanceof HasPage ) ) {
            return;
        }

        final int page = ( ( HasPage ) _delegate.getCoreView() ).getPage();

        try {
            if ( _bookmarkMenuItem == null ) {
                return;
            }

            final List< BookmarkInfo > bookmark = Kernel.getLocalProvider().getBookmarkInfo( _localDir );

            final ImageView image = ( ImageView ) _bookmarkMenuItem.findViewById( R.id.menu_item_image );
            image.setImageResource( bookmark.contains( new BookmarkInfo( page ) ) ? R.drawable.button_bookmark_on : R.drawable.button_bookmark_off );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    private OnClickListener buildMenuClickListener( final FragmentType type ) {
        final DocumentType doc = type.getDocumentType();

        if ( doc != null ) {
            return new OnClickListener() {
                @Override
                public void onClick( final View v ) {
                    final Intent intent = new Intent();

                    if ( _delegate.getCoreView() instanceof HasPage ) {
                        intent.putExtra( CoreViewActivity.EXTRA_PAGE , ( ( HasPage ) _delegate.getCoreView() ).getPage() );
                    }

                    _delegate.changeCoreViewType( doc , intent );
                }
            };
        } else {
            switch ( type ) {
            case HOME:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        _delegate.goBack();
                    }
                };
            case BOOKMARK:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        toggleBookmark();
                    }
                };
            case SETTING:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        _activity.startActivity( new Intent( _activity , SettingActivity.class ) );
                    }
                };
            case SEARCH:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        _activity.onSearchRequested();
                    }
                };
            case BOOKMARKLIST:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        _activity.startActivityForResult(
                                new Intent( _activity , BookmarkActivity.class ).putExtra( BookmarkActivity.EXTRA_PAGE ,
                                        ( ( HasPage ) _delegate.getCoreView() ).getPage() ).putExtra( BookmarkActivity.EXTRA_LOCAL_DIR , _localDir ) ,
                                CoreViewActivity.REQ_BOOKMARK );
                    }
                };
            case TOC:
                return new OnClickListener() {
                    @Override
                    public void onClick( final View v ) {
                        _activity.startActivityForResult(
                                new Intent( _activity , TOCActivity.class ).putExtra( TOCActivity.EXTRA_LOCAL_DIR , _localDir ) ,
                                CoreViewActivity.REQ_TOC );
                    }
                };
            }
            return null;
        }
    }

    private View buildMenuItem( final FragmentType type ) {
        final View view = type.buildButton( getContext() );

        if ( type == FragmentType.BOOKMARK ) {
            _bookmarkMenuItem = view;
            _bookmarkMenuItem.post( new Runnable() {
                @Override
                public void run() {
                    bindBookmarkMenuItemIcon();
                }
            } );
        }

        view.setOnClickListener( buildMenuClickListener( type ) );

        return view;
    }

    private View buildPageInfo() {
        _titleView = new TextView( getContext() );
        updateTitle();

        return _titleView;
    }

    private View buildPrimaryMenu( final DocumentType type ) {
        final FragmentType[] primary = type.getPrimarySwitchFragment();

        final LinearLayout holder = new LinearLayout( getContext() );

        for ( final FragmentType fragment : primary ) {
            holder.addView( buildMenuItem( fragment ) );
        }

        return holder;
    }

    private View buildSecondaryMenu( final DocumentType type ) {
        final FragmentType[] secondary = type.getSecondarySwitchFragment();
        final FragmentType[] subSecondary = type.getSubSecondarySwitchFragment();

        final LinearLayout holder = new LinearLayout( getContext() );

        for ( final FragmentType fragment : secondary ) {
            holder.addView( buildMenuItem( fragment ) );
        }

        // dead code
        if ( subSecondary.length > 0 && subSecondary.length == 0 ) {
            holder.addView( buildSpacer( 0 , 0 , 1 ) );
        }

        for ( final FragmentType fragment : subSecondary ) {
            holder.addView( buildMenuItem( fragment ) );
        }

        return holder;
    }

    private View buildSpacer( final int width , final int height , final float weight ) {
        final View view = new View( getContext() );

        view.setLayoutParams( new LinearLayout.LayoutParams( width , height , weight ) );

        return view;
    }

    private int dp( final float value ) {
        final float density = getResources().getDisplayMetrics().density;

        return Math.round( value * density );
    }

    private void initialize() {
        setLayoutParams( new FrameLayout.LayoutParams( FrameLayout.LayoutParams.FILL_PARENT , FrameLayout.LayoutParams.WRAP_CONTENT ) );
        setOrientation( LinearLayout.VERTICAL );
        setBackgroundColor( 0x80000000 );
        setPadding( dp( 5 ) , dp( 10 ) , dp( 5 ) , dp( 10 ) );
        setVisibility( View.GONE );
    }

    public void onPageChanged() {
        bindBookmarkMenuItemIcon();
        updateTitle();
    }

    public void setType( final DocumentType type ) {
        removeAllViews();

        addView( buildPageInfo() );
        addView( buildSpacer( 0 , dp( 10 ) , 0 ) );
        addView( buildPrimaryMenu( type ) );
        addView( buildSpacer( 0 , dp( 10 ) , 0 ) );
        addView( buildSecondaryMenu( type ) );
    }

    private void toggleBookmark() {
        try {
            if ( !( _delegate.getCoreView() instanceof HasPage ) ) {
                return;
            }

            final List< BookmarkInfo > bookmarks = Kernel.getLocalProvider().getBookmarkInfo( _localDir );

            final int page = ( ( HasPage ) _delegate.getCoreView() ).getPage();

            final BookmarkInfo bookmark = new BookmarkInfo( page );
            if ( bookmarks.contains( bookmark ) ) {
                bookmarks.remove( bookmark );
            } else {
                bookmarks.add( bookmark );
            }

            Kernel.getLocalProvider().setBookmarkInfo( _localDir , bookmarks );

            bindBookmarkMenuItemIcon();
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }

    private void updateTitle() {
        try {
            final int page = ( ( HasPage ) _delegate.getCoreView() ).getPage();
            final int pages = ( ( HasPage ) _delegate.getCoreView() ).getPages();

            final String title = String.format( "%s ( %d / %d page )" , Kernel.getLocalProvider().getTOCText( _localDir , page ) , page + 1 , pages );
            _titleView.setText( title );
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
        } catch ( final JSONException e ) {
            e.printStackTrace();
            getContext().sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
        }
    }
}
