package jp.archilogic.docnext.util;

import java.lang.reflect.Type;

import jp.archilogic.docnext.type.BindingType;
import jp.archilogic.docnext.type.FlowDirectionType;
import net.arnx.jsonic.JSON;

public class CustomJSON extends JSON {
    @Override
    protected < T > T postparse( final Context context , final Object value , final Class< ? extends T > cls , final Type type ) throws Exception {
        if ( BindingType.class.isAssignableFrom( cls ) ) {
            if ( value == null ) {
                return cls.cast( BindingType.RIGHT );
            }

            if ( value instanceof String ) {
                return cls.cast( BindingType.fromJSON( ( String ) value ) );
            }
        }

        if ( FlowDirectionType.class.isAssignableFrom( cls ) ) {
            if ( value == null ) {
                return cls.cast( FlowDirectionType.TO_LEFT );
            }

            if ( value instanceof String ) {
                return cls.cast( FlowDirectionType.fromJSON( ( String ) value ) );
            }
        }

        return super.postparse( context , value , cls , type );
    }

    @Override
    protected Object preformat( final Context context , final Object value ) throws Exception {
        if ( value instanceof BindingType ) {
            return ( ( BindingType ) value ).toJSON();
        }

        if ( value instanceof FlowDirectionType ) {
            return ( ( FlowDirectionType ) value ).toJSON();
        }

        return super.preformat( context , value );
    }
}
