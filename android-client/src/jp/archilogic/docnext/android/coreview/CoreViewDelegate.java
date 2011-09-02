package jp.archilogic.docnext.android.coreview;

import android.content.Intent;

public interface CoreViewDelegate {
    void backToRootView( Intent data );

    void goBack();
}
