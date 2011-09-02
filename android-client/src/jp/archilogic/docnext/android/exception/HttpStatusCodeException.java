package jp.archilogic.docnext.android.exception;

import java.io.IOException;

@SuppressWarnings( "serial" )
public class HttpStatusCodeException extends IOException {
    private final int _statusCode;
    private final String _responseBody;

    public HttpStatusCodeException( final int statusCode , final String responseBody ) {
        super();

        _statusCode = statusCode;
        _responseBody = responseBody;
    }

    public String getResponseBody() {
        return _responseBody;
    }

    public int getStatusCode() {
        return _statusCode;
    }
}
