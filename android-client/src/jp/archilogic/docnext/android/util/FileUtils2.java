package jp.archilogic.docnext.android.util;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

public class FileUtils2 {
    /**
     * Workaround for XOOM (or honeycomb FUSE file-system) not allow File#setLastModified
     */
    public static void touch( final File file ) throws IOException {
        if ( !file.exists() ) {
            final OutputStream out = FileUtils.openOutputStream( file );
            IOUtils.closeQuietly( out );
        }
    }
}
