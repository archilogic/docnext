package jp.archilogic.docnext.android.info;

public class BookmarkInfo {
    /**
     * means position for text-view (should add 'position' field, if need compatibility with image-view)
     */
    public int page;
    // XXX text is not needed to save as JSON
    public String text;

    public BookmarkInfo() {
    }

    public BookmarkInfo( final int page ) {
        this.page = page;
    }

    @Override
    public boolean equals( final Object obj ) {
        if ( this == obj ) {
            return true;
        }

        if ( obj == null || getClass() != obj.getClass() ) {
            return false;
        }

        final BookmarkInfo other = ( BookmarkInfo ) obj;

        return page == other.page;
    }

    @Override
    public int hashCode() {
        final int prime = 31;

        int result = 1;
        result = prime * result + page;

        return result;
    }
}
