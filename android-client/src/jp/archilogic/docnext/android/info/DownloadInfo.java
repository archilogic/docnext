package jp.archilogic.docnext.android.info;


public class DownloadInfo {
    public String id;
    public String localDir;
    public String endpoint;
    public boolean isSample;

    public DownloadInfo() {
    }

    public DownloadInfo( final String id , final String localDir , final String endpoint , final boolean isSample ) {
        this.id = id;
        this.localDir = localDir;
        this.endpoint = endpoint;
        this.isSample = isSample;
    }
}
