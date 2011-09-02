package jp.archilogic.docnext.dto;

public class DividePage {
    public int page;
    public int number;

    public DividePage() {
    }

    public DividePage( int page , int number ) {
        this.page = page;
        this.number = number;
    }
}
