package jp.archilogic.docnext.android.util;

import java.io.IOException;
import java.io.InputStream;

import jp.archilogic.docnext.android.exception.HttpStatusCodeException;

import org.apache.commons.io.IOUtils;
import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.DeflateDecompressingEntity;
import org.apache.http.client.entity.GzipDecompressingEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.params.HttpClientParams;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;

public class NetUtil {
    private static final int TIMEOUT = 20 * 1000;

    private static NetUtil _instance = null;

    public static NetUtil get() {
        if ( _instance == null ) {
            _instance = new NetUtil();
        }

        return _instance;
    }

    private final HttpClient _client;

    private NetUtil() {
        final HttpParams params = new BasicHttpParams();
        HttpConnectionParams.setConnectionTimeout( params , TIMEOUT );
        HttpConnectionParams.setSoTimeout( params , TIMEOUT );
        HttpClientParams.setRedirecting( params , true );

        _client = new DefaultHttpClient( params );
    }

    public HttpResponse asResponse( final HttpUriRequest req ) throws IOException {
        return _client.execute( req );
    }

    public InputStream asStream( final HttpResponse res ) throws IOException {
        final int statusCode = res.getStatusLine().getStatusCode();
        if ( statusCode < 400 ) {
            return decompress( res.getEntity() );
        } else {
            throw new HttpStatusCodeException( statusCode , IOUtils.toString( decompress( res.getEntity() ) ) );
        }
    }

    private InputStream decompress( final HttpEntity entity ) throws IOException {
        final Header encodingHeader = entity.getContentEncoding();

        if ( encodingHeader != null ) {
            final String encoding = encodingHeader.getValue().toLowerCase();

            if ( encoding.equals( "gzip" ) ) {
                return new GzipDecompressingEntity( entity ).getContent();
            } else if ( encoding.equals( "deflate" ) ) {
                return new DeflateDecompressingEntity( entity ).getContent();
            }
        }

        return entity.getContent();
    }

    public InputStream get( final String url ) throws IOException {
        return asStream( asResponse( new HttpGet( url ) ) );
    }
}
