package jp.archilogic.docnext.converter;

import java.util.List;

import com.google.common.collect.Lists;

public class ListConverter {
    public static < E , D > List< D > toDtos( List< E > entities , IEntityToDtoConverter< E , D > converter ) {
        List< D > ret = Lists.newArrayList();

        for ( E entity : entities ) {
            ret.add( converter.toDto( entity ) );
        }

        return ret;
    }
}
