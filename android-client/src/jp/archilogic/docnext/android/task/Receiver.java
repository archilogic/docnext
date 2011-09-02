package jp.archilogic.docnext.android.task;

import jp.archilogic.docnext.android.type.TaskErrorType;

public interface Receiver< T > {
    void error( TaskErrorType error );

    void receive( T result );

}
