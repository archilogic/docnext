package jp.archilogic.docnext.exception;

import flex.messaging.MessageException;

@SuppressWarnings( "serial" )
public class NotFoundException extends MessageException {
    public NotFoundException() {
        setCode( "NotFound" );
    }
}
