package jp.archilogic.docnext.android.service;

import java.io.File;
import java.io.IOException;
import java.util.List;

import jp.archilogic.docnext.android.Kernel;
import jp.archilogic.docnext.android.R;
import jp.archilogic.docnext.android.activity.CoreViewActivity;
import jp.archilogic.docnext.android.exception.NoMediaMountException;
import jp.archilogic.docnext.android.info.DocInfo;
import jp.archilogic.docnext.android.info.DownloadInfo;
import jp.archilogic.docnext.android.info.ImageInfo;
import jp.archilogic.docnext.android.meta.DocumentType;
import jp.archilogic.docnext.android.provider.local.LocalPathManager;
import jp.archilogic.docnext.android.provider.remote.RemoteProvider;
import jp.archilogic.docnext.android.task.FileReceiver;
import jp.archilogic.docnext.android.type.TaskErrorType;
import jp.archilogic.docnext.android.util.ImageLevelUtil;
import net.arnx.jsonic.JSONException;

import org.apache.commons.io.FileUtils;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.FileObserver;
import android.os.Handler;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.widget.RemoteViews;

import com.google.common.base.Function;
import com.google.common.collect.Lists;

public class DownloadService extends Service {
    private class DownloadReceiver implements FileReceiver< Void > {
        @Override
        public void cancelled() {
            checkAbort();
        }

        @Override
        public void downloadComplete() {
        }

        @Override
        public void error( final TaskErrorType error ) {
            sendBroadcast( new Intent( BROADCAST_DOWNLOAD_FAILED ). //
                    putExtra( EXTRA_ERROR , error ) );

            switch ( error ) {
            case NETWORK_UNAVAILABLE:
            case NETWORK_ERROR:
                final Notification notification =
                        new Notification( R.drawable.image_notification_error , getString( R.string.network_error_notification_text ) ,
                                System.currentTimeMillis() );

                notification.setLatestEventInfo( getApplicationContext() , getString( R.string.network_error_notification_title ) ,
                        getString( R.string.network_error_notification_text ) ,
                        PendingIntent.getService( _self , 0 , new Intent( _self , DownloadService.class ) , 0 ) );
                notification.flags |= Notification.FLAG_AUTO_CANCEL;

                ( ( NotificationManager ) getSystemService( NOTIFICATION_SERVICE ) ).notify( NETWORK_ERROR_NOTIFICATION_ID , notification );
                break;
            case NO_STORAGE_SPACE:
            case STORAGE_NOT_MOUNTED:
                break;
            default:
                throw new RuntimeException( "assert" );
            }

            try {
                if ( !Kernel.getLocalProvider().isImageInitDownloaded( _info.localDir ) ) {
                    Kernel.getLocalProvider().setDownloadInfo( null );
                }
            } catch ( final NoMediaMountException e ) {
                e.printStackTrace();
                sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
                stop();
                return;
            } catch ( final JSONException e ) {
                e.printStackTrace();
                sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
                stop();
                return;
            }

            stop();
        }

        @Override
        public void receive( final Void result ) {
            _currentTask = null;
        }
    }

    private static class TexturePosition {
        int level;
        int px;
        int py;

        TexturePosition( final int level , final int px , final int py ) {
            this.level = level;
            this.px = px;
            this.py = py;
        }
    }

    private static final String PREFIX = DownloadService.class.getName();

    public static final String BROADCAST_DOWNLOAD_PROGRESS = PREFIX + ".download.progress";
    public static final String BROADCAST_DOWNLOAD_FAILED = PREFIX + ".download.faileda";
    public static final String BROADCAST_DOWNLOAD_DOWNLOADED = PREFIX + ".download.downloaded";
    public static final String BROADCAST_DOWNLOAD_INIT_DOWNLOADED = PREFIX + ".download.init.downloaded";
    public static final String BROADCAST_DOWNLOAD_ABORTED = PREFIX + ".download.aborted";
    public static final String BROADCAST_DOWNLOAD_COMPLETED = PREFIX + ".download.completed";

    public static final String EXTRA_CURRENT = PREFIX + ".extra.current";
    public static final String EXTRA_TOTAL = PREFIX + ".extra.total";
    public static final String EXTRA_ERROR = PREFIX + ".extra.error";

    public static final String EXTRA_PAGE = PREFIX + ".extra.page";
    public static final String EXTRA_LEVEL = PREFIX + ".extra.level";
    public static final String EXTRA_PX = PREFIX + ".extra.px";
    public static final String EXTRA_PY = PREFIX + ".extra.py";

    public static final int NETWORK_ERROR_NOTIFICATION_ID = 12345;

    private static final int PROGRESS_NOTIFICATION_ID = 23456;
    private static final int NOTIFY_DURATION = 1000;

    private final DownloadService _self = this;

    private boolean _stopAndDelete = false;

    private DownloadInfo _info;
    private DocInfo _doc;
    private FileObserver _observer;

    private AsyncTask< ? , ? , ? > _currentTask;

    private int _progress = 0;
    private int _progressTotal = Integer.MAX_VALUE;

    private Notification _notification;
    private long _latestNotifyTime;

    // private Map< Integer , PerDocumentStatus /* boolean info, boolean image, boolean searchIndex, boolean text,
    // boolean textContent */ >
    // _documentStatus;
    // private Map< Integer , Map< Integer , PerPageStatus /* { boolean[][] texture, boolean thumbnail, boolean
    // searchRegion } */ > > _pageStatus;

    private int calcImagesPerPage( final ImageInfo image ) {
        int ret = 0;

        final int minLevel = ImageLevelUtil.getMinLevel( getResources() , image.maxLevel );
        final int maxLevel = ImageLevelUtil.getMaxLevel( minLevel , image.maxLevel , image.maxNumberOfLevel );

        final int width = ( int ) ( RemoteProvider.TEXTURE_SIZE * Math.pow( 2 , minLevel ) );
        final int height = image.height * width / image.width;

        for ( int level = minLevel ; level <= maxLevel ; level++ ) {
            if ( level != image.maxLevel || !image.isUseActualSize ) {
                final int factor = ( int ) Math.pow( 2 , level - minLevel );

                final int nx = ( width * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                final int ny = ( height * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;

                ret += nx * ny;
            } else {
                final int nx = ( image.width - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                final int ny = ( image.height - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;

                ret += nx * ny;
            }
        }

        return ret;
    }

    private int calcProgressTotal() {
        try {
            int ret = 0;

            final DocInfo doc = Kernel.getLocalProvider().getInfo( _info.localDir );

            for ( final DocumentType type : _doc.types ) {
                switch ( type ) {
                case IMAGE:
                    // texture, thumbnail, regions, index

                    final ImageInfo image = Kernel.getLocalProvider().getImageInfo( _info.localDir );

                    ret += ( calcImagesPerPage( image ) + 1 + 1 ) * doc.pages + 1;

                    break;
                default:
                    throw new RuntimeException( "assert" );
                }
            }

            return ret;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return 0;
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return 0;
        }
    }

    private boolean checkAbort() {
        try {
            if ( _stopAndDelete ) {
                deleteLocalDir();

                sendBroadcast( new Intent( BROADCAST_DOWNLOAD_ABORTED ) );

                Kernel.getLocalProvider().setDownloadInfo( null );

                stop();

                return true;
            }

            return false;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return false;
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return false;
        }
    }

    private void checkDocInfo( final int index ) {
        try {
            if ( index < _doc.types.size() ) {
                switch ( _doc.types.get( index ) ) {
                case IMAGE:
                    ensureImageInfo( index );
                    break;
                default:
                    throw new RuntimeException( "assert" );
                }
            } else {
                _progressTotal = calcProgressTotal();

                ensureContent( 0 );
            }
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        }
    }

    private void deleteLocalDir() {
        try {
            FileUtils.deleteDirectory( new File( _info.localDir ) );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        }
    }

    private void ensureContent( final int index ) {
        try {
            if ( index < _doc.types.size() ) {
                switch ( _doc.types.get( index ) ) {
                case IMAGE:
                    final ImageInfo image = Kernel.getLocalProvider().getImageInfo( _info.localDir );

                    ensureImageTexture( index , image , 0 , ImageLevelUtil.getMinLevel( getResources() , image.maxLevel ) , 0 , 0 );
                    break;
                default:
                    throw new RuntimeException( "assert" );
                }
            } else {
                Kernel.getLocalProvider().setCompleted( _info.localDir );

                sendBroadcast( new Intent( BROADCAST_DOWNLOAD_COMPLETED ) );

                Kernel.getLocalProvider().setDownloadInfo( null );

                stop();
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        }
    }

    private void ensureDocInfo() {
        try {
            _doc = Kernel.getLocalProvider().getInfo( _info.localDir );

            if ( _doc == null ) {
                executeTask( Kernel.getRemoteProvider().getInfo( getApplicationContext() , new DownloadReceiver() {
                    @Override
                    public void receive( final Void result ) {
                        super.receive( result );

                        try {
                            if ( checkAbort() ) {
                                return;
                            }

                            _doc = Kernel.getLocalProvider().getInfo( _info.localDir );

                            checkDocInfo( 0 );
                        } catch ( final NoMediaMountException e ) {
                            e.printStackTrace();
                            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
                            stop();
                            return;
                        } catch ( final JSONException e ) {
                            e.printStackTrace();
                            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
                            stop();
                            return;
                        }
                    }
                } , _info.endpoint , _info.localDir ) );
            } else {
                checkDocInfo( 0 );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        }
    }

    private void ensureImageInfo( final int index ) {
        try {
            final ImageInfo image = Kernel.getLocalProvider().getImageInfo( _info.localDir );

            if ( image == null ) {
                executeTask( Kernel.getRemoteProvider().getImageInfo( getApplicationContext() , new DownloadReceiver() {
                    @Override
                    public void receive( final Void result ) {
                        super.receive( result );

                        if ( checkAbort() ) {
                            return;
                        }

                        try {
                            Kernel.getLocalProvider().setImageInitDownloaded( _info.localDir );

                            if ( index == 0 ) {
                                sendBroadcast( new Intent( BROADCAST_DOWNLOAD_INIT_DOWNLOADED ) );
                            }

                            checkDocInfo( index + 1 );
                        } catch ( final NoMediaMountException e ) {
                            e.printStackTrace();
                            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
                            stop();
                        } catch ( final JSONException e ) {
                            e.printStackTrace();
                            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
                            stop();
                        }
                    }
                } , _info.endpoint , _info.localDir ) );
            } else {
                checkDocInfo( index + 1 );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        }
    }

    private void ensureImageRegions( final int index , final ImageInfo image , final int page ) {
        try {
            final Uri uri = Uri.parse( _info.endpoint );

            if ( uri.getPathSegments().contains( "docnext_p" ) || uri.getPathSegments().contains( "docnext_p_c" ) ) {
                ensureImageRegionsAll( index , image );
            } else {
                ensureImageRegionsEach( index , image , page );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    private void ensureImageRegionsAll( final int index , final ImageInfo image ) throws NoMediaMountException {
        final List< Integer > required = getRequiredImageRegions();

        if ( required.size() > 0 ) {
            executeTask( Kernel.getRemoteProvider().getImageRegionsAll( getApplicationContext() , new DownloadReceiver() {
                @Override
                public void downloadComplete() {
                    incAndDispatchProgress();
                }

                @Override
                public void receive( final Void result ) {
                    super.receive( result );

                    if ( checkAbort() ) {
                        return;
                    }

                    ensureImageTextIndex( index , image );
                }
            } , _info.endpoint , _info.localDir , Lists.transform( required , new Function< Integer , String >() {
                @Override
                public String apply( final Integer from ) {
                    return new LocalPathManager().getImageRegionsName( from );
                }
            } ) ) );
        } else {
            new Handler().post( new Runnable() {
                @Override
                public void run() {
                    ensureImageTextIndex( index , image );
                }
            } );
        }
    }

    private void ensureImageRegionsEach( final int index , final ImageInfo image , final int page ) throws NoMediaMountException {
        if ( page < _doc.pages ) {
            if ( Kernel.getLocalProvider().getImageRegions( _info.localDir , page ) == null ) {
                executeTask( Kernel.getRemoteProvider().getImageRegions( getApplicationContext() , new DownloadReceiver() {
                    @Override
                    public void receive( final Void result ) {
                        super.receive( result );

                        if ( checkAbort() ) {
                            return;
                        }

                        incAndDispatchProgress();

                        ensureImageRegions( index , image , page + 1 );
                    }
                } , _info.endpoint , _info.localDir , page ) );
            } else {
                // for stack over flow :(
                new Handler().post( new Runnable() {
                    @Override
                    public void run() {
                        incAndDispatchProgress();

                        ensureImageRegions( index , image , page + 1 );
                    }
                } );
            }
        } else {
            ensureImageTextIndex( index , image );
        }
    }

    private void ensureImageTextIndex( final int index , final ImageInfo image ) {
        try {
            if ( !Kernel.getLocalProvider().isImageTextIndexExists( _info.localDir ) ) {
                executeTask( Kernel.getRemoteProvider().getImageTextIndex( getApplicationContext() , new DownloadReceiver() {
                    @Override
                    public void receive( final Void result ) {
                        super.receive( result );

                        if ( checkAbort() ) {
                            return;
                        }

                        incAndDispatchProgress();

                        ensureContent( index + 1 );
                    }
                } , _info.endpoint , _info.localDir ) );
            } else {
                incAndDispatchProgress();

                ensureContent( index + 1 );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    private void ensureImageTexture( final int index , final ImageInfo image , final int page , final int level , final int px , final int py ) {
        try {
            if ( page < _doc.pages ) {
                final int minLevel = ImageLevelUtil.getMinLevel( getResources() , image.maxLevel );
                final int maxLevel = ImageLevelUtil.getMaxLevel( minLevel , image.maxLevel , image.maxNumberOfLevel );

                final Uri uri = Uri.parse( _info.endpoint );

                if ( uri.getPathSegments().contains( "docnext_p" ) || uri.getPathSegments().contains( "docnext_p_c" ) ) {
                    ensureImageTexturePerPage( index , image , page , minLevel , maxLevel );
                } else {
                    ensureImageTexturePerTexture( index , image , page , level , px , py , minLevel , maxLevel );
                }
            } else {
                ensureImageThumbnail( index , image , 0 );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    private void ensureImageTexturePerPage( final int index , final ImageInfo image , final int page , final int minLevel , final int maxLevel )
            throws NoMediaMountException {
        final List< TexturePosition > required = getRequiredTextures( image , page , minLevel , maxLevel );

        if ( required.size() > 0 ) {
            executeTask( Kernel.getRemoteProvider().getImageTexturePerPage( getApplicationContext() , new DownloadReceiver() {
                private int seq = 0;

                @Override
                public void downloadComplete() {
                    final TexturePosition pos = required.get( seq++ );

                    sendBroadcast( new Intent( BROADCAST_DOWNLOAD_DOWNLOADED ).putExtra( EXTRA_PAGE , page ).putExtra( EXTRA_LEVEL , pos.level )
                            .putExtra( EXTRA_PX , pos.px ).putExtra( EXTRA_PY , pos.py ) );

                    incAndDispatchProgress();
                }

                @Override
                public void receive( final Void result ) {
                    super.receive( result );

                    if ( checkAbort() ) {
                        return;
                    }

                    ensureImageTexture( index , image , page + 1 , minLevel , 0 , 0 );
                }
            } , _info.endpoint , _info.localDir , Lists.transform( required , new Function< TexturePosition , String >() {
                @Override
                public String apply( final TexturePosition from ) {
                    return new LocalPathManager().getImageTextureName( page , from.level , from.px , from.py , image.isWebp );
                }
            } ) ) );
        } else {
            new Handler().post( new Runnable() {
                @Override
                public void run() {
                    ensureImageTexture( index , image , page + 1 , minLevel , 0 , 0 );
                }
            } );
        }
    }

    private void ensureImageTexturePerTexture( final int index , final ImageInfo image , final int page , final int level , final int px ,
            final int py , final int minLevel , final int maxLevel ) throws NoMediaMountException {
        if ( level <= maxLevel ) {
            int nx;
            int ny;

            if ( level != image.maxLevel || !image.isUseActualSize ) {
                final int width = ( int ) ( RemoteProvider.TEXTURE_SIZE * Math.pow( 2 , minLevel ) );
                final int height = image.height * width / image.width;

                final int factor = ( int ) Math.pow( 2 , level - minLevel );

                nx = ( width * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                ny = ( height * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            } else {
                nx = ( image.width - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                ny = ( image.height - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            }

            if ( px < nx ) {
                if ( py < ny ) {
                    if ( Kernel.getLocalProvider().getImageTexturePath( _info.localDir , page , level , px , py , image.isWebp ) == null ) {
                        executeTask( Kernel.getRemoteProvider().getImageTexture( getApplicationContext() , new DownloadReceiver() {
                            @Override
                            public void downloadComplete() {
                                sendBroadcast( new Intent( BROADCAST_DOWNLOAD_DOWNLOADED ).putExtra( EXTRA_PAGE , page )
                                        .putExtra( EXTRA_LEVEL , level ).putExtra( EXTRA_PX , px ).putExtra( EXTRA_PY , py ) );
                            }

                            @Override
                            public void receive( final Void result ) {
                                super.receive( result );

                                if ( checkAbort() ) {
                                    return;
                                }

                                incAndDispatchProgress();

                                ensureImageTexture( index , image , page , level , px , py + 1 );
                            }
                        } , _info.endpoint , _info.localDir , page , level , px , py , image.isWebp ) );
                    } else {
                        // for stack over flow :(
                        new Handler().post( new Runnable() {
                            @Override
                            public void run() {
                                incAndDispatchProgress();

                                ensureImageTexture( index , image , page , level , px , py + 1 );
                            }
                        } );
                    }
                } else {
                    ensureImageTexture( index , image , page , level , px + 1 , 0 );
                }
            } else {
                ensureImageTexture( index , image , page , level + 1 , 0 , 0 );
            }
        } else {
            ensureImageTexture( index , image , page + 1 , minLevel , 0 , 0 );
        }
    }

    private void ensureImageThumbnail( final int index , final ImageInfo image , final int page ) {
        try {
            final Uri uri = Uri.parse( _info.endpoint );

            if ( uri.getPathSegments().contains( "docnext_p" ) || uri.getPathSegments().contains( "docnext_p_c" ) ) {
                ensureImageThumbnailAll( index , image );
            } else {
                ensureImageThumbnailEach( index , image , page );
            }
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    private void ensureImageThumbnailAll( final int index , final ImageInfo image ) throws NoMediaMountException {
        final List< Integer > required = getRequiredThumbnails();

        if ( required.size() > 0 ) {
            executeTask( Kernel.getRemoteProvider().getImageThumbnailAll( getApplicationContext() , new DownloadReceiver() {
                @Override
                public void downloadComplete() {
                    incAndDispatchProgress();
                }

                @Override
                public void receive( final Void result ) {
                    super.receive( result );

                    if ( checkAbort() ) {
                        return;
                    }

                    ensureImageRegions( index , image , 0 );
                }
            } , _info.endpoint , _info.localDir , Lists.transform( required , new Function< Integer , String >() {
                @Override
                public String apply( final Integer from ) {
                    return new LocalPathManager().getImageThumbnailName( from );
                }
            } ) ) );
        } else {
            new Handler().post( new Runnable() {
                @Override
                public void run() {
                    ensureImageRegions( index , image , 0 );
                }
            } );
        }
    }

    private void ensureImageThumbnailEach( final int index , final ImageInfo image , final int page ) throws NoMediaMountException {
        if ( page < _doc.pages ) {
            if ( Kernel.getLocalProvider().getImageThumbnailPath( _info.localDir , page ) == null ) {
                executeTask( Kernel.getRemoteProvider().getImageThumbnail( getApplicationContext() , new DownloadReceiver() {
                    @Override
                    public void receive( final Void result ) {
                        super.receive( result );

                        if ( checkAbort() ) {
                            return;
                        }

                        incAndDispatchProgress();

                        ensureImageThumbnail( index , image , page + 1 );
                    }
                } , _info.endpoint , _info.localDir , page ) );
            } else {
                // for stack over flow :(
                new Handler().post( new Runnable() {
                    @Override
                    public void run() {
                        incAndDispatchProgress();

                        ensureImageThumbnail( index , image , page + 1 );
                    }
                } );
            }
        } else {
            ensureImageRegions( index , image , 0 );
        }
    }

    private void executeTask( final AsyncTask< Void , Void , Void > task ) {
        _currentTask = task;
        task.execute();
    }

    private List< Integer > getRequiredImageRegions() throws NoMediaMountException {
        final List< Integer > ret = Lists.newArrayList();

        for ( int page = 0 ; page < _doc.pages ; page++ ) {
            if ( Kernel.getLocalProvider().getImageRegions( _info.localDir , page ) == null ) {
                ret.add( page );
            } else {
                incAndDispatchProgress();
            }
        }

        return ret;
    }

    private List< TexturePosition > getRequiredTextures( final ImageInfo image , final int page , final int minLevel , final int maxLevel )
            throws NoMediaMountException {
        final List< TexturePosition > ret = Lists.newArrayList();

        for ( int level = minLevel ; level <= maxLevel ; level++ ) {
            int nx;
            int ny;

            if ( level != image.maxLevel || !image.isUseActualSize ) {
                final int width = ( int ) ( RemoteProvider.TEXTURE_SIZE * Math.pow( 2 , minLevel ) );
                final int height = image.height * width / image.width;

                final int factor = ( int ) Math.pow( 2 , level - minLevel );

                nx = ( width * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                ny = ( height * factor - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            } else {
                nx = ( image.width - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
                ny = ( image.height - 1 ) / RemoteProvider.TEXTURE_SIZE + 1;
            }

            for ( int px = 0 ; px < nx ; px++ ) {
                for ( int py = 0 ; py < ny ; py++ ) {
                    if ( Kernel.getLocalProvider().getImageTexturePath( _info.localDir , page , level , px , py , image.isWebp ) == null ) {
                        ret.add( new TexturePosition( level , px , py ) );
                    } else {
                        incAndDispatchProgress();
                    }
                }
            }
        }

        return ret;
    }

    private List< Integer > getRequiredThumbnails() throws NoMediaMountException {
        final List< Integer > ret = Lists.newArrayList();

        for ( int page = 0 ; page < _doc.pages ; page++ ) {
            if ( Kernel.getLocalProvider().getImageThumbnailPath( _info.localDir , page ) == null ) {
                ret.add( page );
            } else {
                incAndDispatchProgress();
            }
        }
        return ret;
    }

    private void incAndDispatchProgress() {
        _progress++;

        sendBroadcast( new Intent( BROADCAST_DOWNLOAD_PROGRESS ).putExtra( EXTRA_CURRENT , _progress ).putExtra( EXTRA_TOTAL , _progressTotal ) );

        final long time = SystemClock.elapsedRealtime();

        if ( time - _latestNotifyTime > NOTIFY_DURATION ) {

            _notification.contentView.setProgressBar( R.id.progress , _progressTotal , _progress , false );

            final NotificationManager manager = ( NotificationManager ) getSystemService( Context.NOTIFICATION_SERVICE );
            manager.notify( PROGRESS_NOTIFICATION_ID , _notification );

            _latestNotifyTime = time;
        }
    }

    @Override
    public IBinder onBind( final Intent intent ) {
        return null;
    }

    /**
     * @@ Called only init start (means Service not running on startService
     * @@ onStart() is called only the service is running (not called on restart by task killer)
     */
    @Override
    public void onCreate() {
        super.onCreate();

        try {
            _info = Kernel.getLocalProvider().getDownloadInfo();

            if ( _info != null ) {
                if ( _info.id == null || _info.localDir == null || _info.endpoint == null ) {
                    throw new IllegalArgumentException();
                }

                _observer = new FileObserver( _info.localDir ) {
                    @Override
                    public void onEvent( final int event , final String path ) {
                        if ( event == FileObserver.DELETE_SELF ) {
                            Log.i( "docnext" , "Detect abnormal file deletion. Stop download service." );

                            if ( _currentTask != null ) {
                                _currentTask.cancel( false );
                            }

                            _stopAndDelete = true;
                        }
                    }
                };
                _observer.startWatching();

                sendBroadcast( new Intent( BROADCAST_DOWNLOAD_PROGRESS ). //
                        putExtra( EXTRA_CURRENT , 0 ). //
                        putExtra( EXTRA_TOTAL , Integer.MAX_VALUE ) );
                showNotification();

                ensureDocInfo();
            } else {
                Kernel.getLocalProvider().setDownloadInfo( null );

                stop();
            }
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        if ( _observer != null ) {
            _observer.stopWatching();
            _observer = null;
        }
    }

    @Override
    public void onStart( final Intent intent , final int startId ) {
        super.onStart( intent , startId );

        try {
            if ( Kernel.getLocalProvider().getDownloadInfo() == null ) {
                if ( _currentTask != null ) {
                    _currentTask.cancel( false );
                }

                _stopAndDelete = true;
            }
        } catch ( final JSONException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_BROKEN_FILE ) );
            stop();
            return;
        } catch ( final NoMediaMountException e ) {
            e.printStackTrace();
            sendBroadcast( new Intent( CoreViewActivity.BROADCAST_ERROR_NO_SD_CARD ) );
            stop();
            return;
        }
    }

    private void showNotification() {
        _notification =
                new Notification( R.drawable.image_notification_progress , getString( R.string.notification_progress ) , System.currentTimeMillis() );
        _notification.flags |= Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT | Notification.FLAG_ONLY_ALERT_ONCE;
        _notification.contentIntent = PendingIntent.getActivity( this , 0 , new Intent() , 0 );

        _notification.contentView = new RemoteViews( getPackageName() , R.layout.notification_progress );

        final NotificationManager manager = ( NotificationManager ) getSystemService( NOTIFICATION_SERVICE );
        manager.notify( PROGRESS_NOTIFICATION_ID , _notification );

        _latestNotifyTime = SystemClock.elapsedRealtime();
    }

    private void stop() {
        final NotificationManager manager = ( NotificationManager ) getSystemService( NOTIFICATION_SERVICE );
        manager.cancel( PROGRESS_NOTIFICATION_ID );

        stopSelf();
    }
}
