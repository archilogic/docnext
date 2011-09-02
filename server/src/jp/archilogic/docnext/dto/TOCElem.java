package jp.archilogic.docnext.dto;

public class TOCElem {
    public int page;
    public String text;

    public TOCElem() {
    }

    public TOCElem( int page , String text ) {
        this.page = page;
        this.text = text;
    }
}
