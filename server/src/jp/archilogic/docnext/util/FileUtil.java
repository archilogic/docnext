package jp.archilogic.docnext.util;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;

import org.apache.commons.io.FilenameUtils;

import com.google.common.collect.Lists;

public class FileUtil {
    public static String createSameDirPath( String baseFile , String filename ) {
        return FilenameUtils.getFullPathNoEndSeparator( baseFile ) + File.separator + filename;
    }

    public static void safeDelete( String path ) {
        File f = new File( path );
        if ( f.exists() ) {
            f.delete();
        }
    }

    public static byte[] toBytes( String filePath ) {
        List< Byte > temp = Lists.newArrayList();
        try {
            BufferedInputStream bufferedInputStream = new BufferedInputStream( new FileInputStream( filePath ) );

            int t;
            while ( ( t = bufferedInputStream.read() ) != -1 ) {
                temp.add( ( byte ) t );
            }

            bufferedInputStream.close();
        } catch ( FileNotFoundException e ) {
            throw new RuntimeException( e );
        } catch ( IOException e ) {
            throw new RuntimeException( e );
        }

        byte[] ret = new byte[ temp.size() ];
        for ( int i = 0 , length = ret.length ; i < length ; i++ ) {
            ret[ i ] = temp.get( i );
        }

        return ret;
    }

    public static void toFile( byte[] data , String path ) {
        try {
            File outFile = new File( path );
            if ( outFile.getParentFile().mkdirs() ) {
                FileOutputStream out = new FileOutputStream( path );
                out.write( data );
                out.flush();
            } else {
                throw new RuntimeException( "Cannot create directory : " + outFile.getParent() );
            }
        } catch ( FileNotFoundException e ) {
            e.printStackTrace();
            throw new RuntimeException( e );
        } catch ( IOException e ) {
            e.printStackTrace();
            throw new RuntimeException( e );
        }
    }
}
