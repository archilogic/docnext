package jp.archilogic.docnext.android.type;

public enum BindingType {
    LEFT( "left" ) , RIGHT( "right" );

    public static BindingType fromJSON( final String json ) {
        if ( json.equals( LEFT.toJSON() ) ) {
            return LEFT;
        }

        if ( json.equals( RIGHT.toJSON() ) ) {
            return RIGHT;
        }

        throw new RuntimeException();
    }

    private final String _json;

    private BindingType( final String json ) {
        _json = json;
    }

    public String toJSON() {
        return _json;
    }
}
