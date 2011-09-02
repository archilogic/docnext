package jp.archilogic.docnext.type;

public enum FlowDirectionType {
    TO_RIGHT( "right" ) , TO_LEFT( "left" );

    public static FlowDirectionType fromJSON( final String json ) {
        if ( json.equals( TO_RIGHT.toJSON() ) ) {
            return TO_RIGHT;
        }

        if ( json.equals( TO_LEFT.toJSON() ) ) {
            return TO_LEFT;
        }

        throw new RuntimeException();
    }

    private final String _json;

    private FlowDirectionType( final String json ) {
        _json = json;
    }

    public String toJSON() {
        return _json;
    }
}
