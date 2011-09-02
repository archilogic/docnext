package jp.archilogic.docnext.entity;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.Lob;

import net.arnx.jsonic.JSON;

@Entity
public class Document {
    public static class DocumentJson {
        public String name;
        public String fileName;
    }

    @Id
    @GeneratedValue
    public Long id;

    @Column( nullable = false )
    public Boolean processing;

    @Column( nullable = false )
    @Lob
    private String json;

    public String getFileName() {
        return getJson().fileName;
    }

    private DocumentJson getJson() {
        return json != null ? JSON.decode( json , DocumentJson.class ) : new DocumentJson();
    }

    public String getName() {
        return getJson().name;
    }

    public void setFileName( final String fileName ) {
        final DocumentJson json = getJson();
        json.fileName = fileName;
        setJson( json );
    }

    private void setJson( final DocumentJson instance ) {
        json = JSON.encode( instance );
    }

    public void setName( final String name ) {
        final DocumentJson json = getJson();
        json.name = name;
        setJson( json );
    }
}
