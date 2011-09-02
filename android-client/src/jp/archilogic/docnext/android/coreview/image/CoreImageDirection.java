package jp.archilogic.docnext.android.coreview.image;

public enum CoreImageDirection {
    L2R , R2L , T2B , B2T;

    private static final int PAGE_CHANGE_THREASHOLD = 4;

    boolean canMoveHorizontal() {
        switch ( this ) {
        case L2R:
        case R2L:
            return true;
        case T2B:
        case B2T:
            return false;
        default:
            throw new RuntimeException();
        }
    }

    boolean canMoveVertical() {
        return !canMoveHorizontal();
    }

    CoreImageCorner getCorner( final boolean isNext ) {
        switch ( this ) {
        case L2R:
            return isNext ? CoreImageCorner.TOP_LEFT : CoreImageCorner.BOTTOM_RIGHT;
        case R2L:
            return isNext ? CoreImageCorner.TOP_RIGHT : CoreImageCorner.BOTTOM_LEFT;
        case T2B:
            return isNext ? CoreImageCorner.TOP_LEFT : CoreImageCorner.BOTTOM_RIGHT;
        case B2T:
            return isNext ? CoreImageCorner.TOP_RIGHT : CoreImageCorner.BOTTOM_LEFT;
        default:
            throw new RuntimeException();
        }
    }

    boolean shouldChangeToNext( final CoreImageState engine ) {
        switch ( this ) {
        case L2R:
            return engine.matrix.tx < engine.surfaceSize.width - engine.surfaceSize.width / PAGE_CHANGE_THREASHOLD - engine.pageSize.width
                    * engine.matrix.scale - engine.getHorizontalPadding() * 2;
        case R2L:
            return engine.matrix.tx > engine.surfaceSize.width / PAGE_CHANGE_THREASHOLD;
        case T2B:
            return engine.matrix.ty < engine.surfaceSize.height - engine.surfaceSize.height / PAGE_CHANGE_THREASHOLD - engine.pageSize.height
                    * engine.matrix.scale - engine.getVerticalPadding() * 2;
        case B2T:
            return engine.matrix.ty > engine.surfaceSize.height / PAGE_CHANGE_THREASHOLD;
        default:
            throw new RuntimeException();
        }
    }

    boolean shouldChangeToPrev( final CoreImageState engine ) {
        switch ( this ) {
        case L2R:
            return engine.matrix.tx > engine.surfaceSize.width / PAGE_CHANGE_THREASHOLD;
        case R2L:
            return engine.matrix.tx < engine.surfaceSize.width - engine.surfaceSize.width / PAGE_CHANGE_THREASHOLD - engine.pageSize.width
                    * engine.matrix.scale - engine.getHorizontalPadding() * 2;
        case T2B:
            return engine.matrix.ty > engine.surfaceSize.height / PAGE_CHANGE_THREASHOLD;
        case B2T:
            return engine.matrix.ty < engine.surfaceSize.height - engine.surfaceSize.height / PAGE_CHANGE_THREASHOLD - engine.pageSize.height
                    * engine.matrix.scale - engine.getVerticalPadding() * 2;
        default:
            throw new RuntimeException();
        }
    }

    int toXSign() {
        switch ( this ) {
        case L2R:
            return 1;
        case R2L:
            return -1;
        case T2B:
        case B2T:
            return 0;
        default:
            throw new RuntimeException();
        }
    }

    int toYSign() {
        switch ( this ) {
        case L2R:
        case R2L:
            return 0;
        case T2B:
            return 1;
        case B2T:
            return -1;
        default:
            throw new RuntimeException();
        }
    }

    void updateOffset( final CoreImageState engine , final boolean isNext ) {
        final int sign = ( this == L2R || this == T2B ) ^ isNext ? -1 : 1;

        switch ( this ) {
        case L2R:
        case R2L:
            engine.matrix.tx += sign * engine.pageSize.width * engine.matrix.scale;
            break;
        case T2B:
        case B2T:
            engine.matrix.ty += sign * engine.pageSize.height * engine.matrix.scale;
            break;
        default:
            throw new RuntimeException();
        }
    }
}
