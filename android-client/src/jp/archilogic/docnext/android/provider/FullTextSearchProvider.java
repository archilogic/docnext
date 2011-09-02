package jp.archilogic.docnext.android.provider;

import java.io.File;
import java.io.IOException;
import java.util.List;

import jp.archilogic.docnext.android.provider.local.LocalPathManager;

import org.apache.lucene.analysis.cjk.CJKAnalyzer;
import org.apache.lucene.document.Document;
import org.apache.lucene.queryParser.ParseException;
import org.apache.lucene.queryParser.QueryParser;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.ScoreDoc;
import org.apache.lucene.store.FSDirectory;
import org.apache.lucene.util.Version;

import android.app.SearchManager;
import android.content.ContentProvider;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.database.CharArrayBuffer;
import android.database.ContentObserver;
import android.database.Cursor;
import android.database.DataSetObserver;
import android.net.Uri;
import android.os.Bundle;
import android.provider.BaseColumns;

import com.google.common.base.Predicate;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;

public class FullTextSearchProvider extends ContentProvider {
    public static class SuggestCursor implements Cursor {
        private List< SuggestInfo > _data;
        private int _position;

        public SuggestCursor( final List< SuggestInfo > data ) {
            _data = data;
            _position = -1;
        }

        @Override
        public void close() {
            _data = null;
        }

        @Override
        public void copyStringToBuffer( final int columnIndex , final CharArrayBuffer buffer ) {
            throw new RuntimeException();
        }

        @Override
        public void deactivate() {
            throw new RuntimeException();
        }

        @Override
        public byte[] getBlob( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public int getColumnCount() {
            return SuggestInfo.NAMES.length;
        }

        @Override
        public int getColumnIndex( final String columnName ) {
            return Iterables.indexOf( Lists.newArrayList( SuggestInfo.NAMES ) , new Predicate< String >() {
                @Override
                public boolean apply( final String input ) {
                    return input.equals( columnName );
                }
            } );
        }

        @Override
        public int getColumnIndexOrThrow( final String columnName ) throws IllegalArgumentException {
            final int index = getColumnIndex( columnName );

            if ( index < 0 ) {
                throw new IllegalArgumentException();
            }

            return index;
        }

        @Override
        public String getColumnName( final int columnIndex ) {
            return SuggestInfo.NAMES[ columnIndex ];
        }

        @Override
        public String[] getColumnNames() {
            return SuggestInfo.NAMES;
        }

        @Override
        public int getCount() {
            return _data.size();
        }

        @Override
        public double getDouble( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public Bundle getExtras() {
            return null;
        }

        @Override
        public float getFloat( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public int getInt( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public long getLong( final int columnIndex ) {
            if ( getColumnName( columnIndex ).equals( BaseColumns._ID ) ) {
                return _data.get( _position ).id;
            }

            throw new RuntimeException();
        }

        @Override
        public int getPosition() {
            return _position;
        }

        @Override
        public short getShort( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public String getString( final int columnIndex ) {
            if ( getColumnName( columnIndex ).equals( SearchManager.SUGGEST_COLUMN_TEXT_1 ) ) {
                return _data.get( _position ).suggestText1;
            }

            if ( getColumnName( columnIndex ).equals( SearchManager.SUGGEST_COLUMN_TEXT_2 ) ) {
                return _data.get( _position ).suggestText2;
            }

            if ( getColumnName( columnIndex ).equals( SearchManager.SUGGEST_COLUMN_INTENT_DATA_ID ) ) {
                return _data.get( _position ).suggestIntentDataId;
            }

            if ( getColumnName( columnIndex ).equals( SearchManager.SUGGEST_COLUMN_INTENT_EXTRA_DATA ) ) {
                return _data.get( _position ).suggestIntentExtraData;
            }

            throw new RuntimeException();
        }

        @Override
        public boolean getWantsAllOnMoveCalls() {
            throw new RuntimeException();
        }

        @Override
        public boolean isAfterLast() {
            return _position >= _data.size();
        }

        @Override
        public boolean isBeforeFirst() {
            return _position < 0;
        }

        @Override
        public boolean isClosed() {
            return _data == null;
        }

        @Override
        public boolean isFirst() {
            return _position == 0;
        }

        @Override
        public boolean isLast() {
            return _position == _data.size() - 1;
        }

        @Override
        public boolean isNull( final int columnIndex ) {
            throw new RuntimeException();
        }

        @Override
        public boolean move( final int offset ) {
            throw new RuntimeException();
        }

        @Override
        public boolean moveToFirst() {
            if ( _data.size() == 0 ) {
                return false;
            }

            _position = 0;

            return true;
        }

        @Override
        public boolean moveToLast() {
            if ( _data.size() == 0 ) {
                return false;
            }

            _position = _data.size() - 1;

            return true;
        }

        @Override
        public boolean moveToNext() {
            _position++;

            return _position < _data.size();
        }

        @Override
        public boolean moveToPosition( final int position ) {
            _position = position;

            return _position >= 0 && _position < _data.size();
        }

        @Override
        public boolean moveToPrevious() {
            throw new RuntimeException();
        }

        @Override
        public void registerContentObserver( final ContentObserver observer ) {
            // ignore
        }

        @Override
        public void registerDataSetObserver( final DataSetObserver observer ) {
            // ignore
        }

        @Override
        public boolean requery() {
            throw new RuntimeException();
        }

        @Override
        public Bundle respond( final Bundle extras ) {
            throw new RuntimeException();
        }

        @Override
        public void setNotificationUri( final ContentResolver cr , final Uri uri ) {
            throw new RuntimeException();
        }

        @Override
        public void unregisterContentObserver( final ContentObserver observer ) {
            // ignore
        }

        @Override
        public void unregisterDataSetObserver( final DataSetObserver observer ) {
            // ignore
        }
    }

    private static class SuggestInfo {
        static final String[] NAMES = { BaseColumns._ID , SearchManager.SUGGEST_COLUMN_TEXT_1 , SearchManager.SUGGEST_COLUMN_TEXT_2 ,
                SearchManager.SUGGEST_COLUMN_INTENT_DATA_ID , SearchManager.SUGGEST_COLUMN_INTENT_EXTRA_DATA };

        long id;
        String suggestText1;
        String suggestText2;
        String suggestIntentDataId;
        String suggestIntentExtraData;

        SuggestInfo( final long id , final String suggestText1 , final String suggestText2 , final String suggestIntentDataId ,
                final String suggestIntentExtraData ) {
            this.id = id;
            this.suggestText1 = suggestText1;
            this.suggestText2 = suggestText2;
            this.suggestIntentDataId = suggestIntentDataId;
            this.suggestIntentExtraData = suggestIntentExtraData;
        }
    }

    public static final Uri CONTENT_URI = Uri.parse( "content://android.lucene.CustomContentProvicer" );

    @Override
    public int delete( final Uri uri , final String selection , final String[] selectionArgs ) {
        throw new RuntimeException();
    }

    @Override
    public String getType( final Uri uri ) {
        throw new RuntimeException();
    }

    private String highlight( final String text , final String keyword , final int padding ) {
        final int pos = text.indexOf( keyword );

        if ( pos < 0 ) {
            return null;
        }

        int begin = pos - padding;
        String preEllipsis = "...";

        if ( begin < 0 ) {
            begin = 0;
            preEllipsis = "";
        }

        int end = pos + keyword.length() + padding;
        String postEllipsis = "...";

        if ( end > text.length() ) {
            end = text.length();
            postEllipsis = "";
        }

        return preEllipsis + text.substring( begin , end ).replaceAll( "\n" , "" ).replace( "\r" , "" ) + postEllipsis;
    }

    @Override
    public Uri insert( final Uri uri , final ContentValues values ) {
        throw new RuntimeException();
    }

    @Override
    public boolean onCreate() {
        return false;
    }

    @Override
    public Cursor query( final Uri uri , final String[] projection , final String selection , final String[] selectionArgs , final String sortOrder ) {
        try {
            final String keyword = uri.getLastPathSegment();

            final List< SuggestInfo > suggests = Lists.newArrayList();

            final IndexSearcher searcher =
                    new IndexSearcher( FSDirectory.open( new File( new LocalPathManager().getWorkingImageTextIndexDirPath() ) ) );

            long id = 0;
            for ( final ScoreDoc hit : searcher.search(
                    new QueryParser( Version.LUCENE_31 , "text" , new CJKAnalyzer( Version.LUCENE_31 ) ).parse( keyword ) , 10 ).scoreDocs ) {
                final Document doc = searcher.doc( hit.doc );

                final String highlight = highlight( doc.get( "text" ) , keyword , 5 );

                if ( highlight != null ) {
                    suggests.add( new SuggestInfo( id++ , doc.get( "page" ) , highlight , doc.get( "page" ) , keyword ) );
                }
            }

            searcher.close();

            return new SuggestCursor( suggests );
        } catch ( final IOException e ) {
            throw new RuntimeException( e );
        } catch ( final ParseException e ) {
            throw new RuntimeException( e );
        }
    }

    @Override
    public int update( final Uri uri , final ContentValues values , final String selection , final String[] selectionArgs ) {
        throw new RuntimeException();
    }
}
