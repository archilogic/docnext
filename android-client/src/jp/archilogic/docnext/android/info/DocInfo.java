package jp.archilogic.docnext.android.info;

import java.util.List;

import jp.archilogic.docnext.android.meta.DocumentType;
import jp.archilogic.docnext.android.type.BindingType;
import jp.archilogic.docnext.android.type.FlowDirectionType;

public class DocInfo {
    public String id;
    public List< DocumentType > types;
    public int pages;
    public List< Integer > singlePages;
    public List< TOCElem > toc;
    public String title;
    public String publisher;
    public BindingType binding;
    public FlowDirectionType flow;
}
