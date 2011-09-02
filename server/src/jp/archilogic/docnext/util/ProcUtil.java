package jp.archilogic.docnext.util;

import java.io.IOException;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ProcUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger( ProcUtil.class );

    public static String doProc( final String command ) {
        return doProc( command , false );
    }

    public static String doProc( final String command , final boolean ignoreError ) {
        LOGGER.info( "ProcUtil.doProc: " + command );

        try {
            final Process process = Runtime.getRuntime().exec( command );

            // QQQ consider memory usage?
            final String ret = IOUtils.toString( process.getInputStream() );
            final String error = IOUtils.toString( process.getErrorStream() );

            if ( !error.isEmpty() ) {
                if ( ignoreError ) {
                    LOGGER.error( "Error : " + error + "(for command: " + command + ")" );
                } else {
                    throw new RuntimeException( "Error : " + error + "(for command: " + command + ")" );
                }
            }

            process.waitFor();

            return ret.toString();
        } catch ( final IOException e ) {
            e.printStackTrace();
            throw new RuntimeException( e );
        } catch ( final InterruptedException e ) {
            e.printStackTrace();
            throw new RuntimeException( e );
        }
    }
}
