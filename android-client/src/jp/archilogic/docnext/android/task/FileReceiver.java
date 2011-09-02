package jp.archilogic.docnext.android.task;

public interface FileReceiver< T > extends Receiver< T > {
    void cancelled();

    void downloadComplete();
}
