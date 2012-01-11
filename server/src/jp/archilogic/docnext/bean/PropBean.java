package jp.archilogic.docnext.bean;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PropBean {
    @Value( "${path.repository}" )
    public String repository;

    @Value( "${path.host}" )
    public String host;

    @Value( "${path.pdfToPpm}" )
    public String pdfToPpm;

    @Value( "${path.identify}" )
    public String identify;

    @Value( "${path.pdfinfo}" )
    public String pdfInfo;

    @Value( "${path.dnconv}" )
    public String dnconv;

    @Value( "${path.tmp}" )
    public String tmp;

    @Value( "${image.texture}" )
    public boolean forTexture;

    @Value( "${path.batchTargetDir}" )
    public String batchTargetDir;

    @Value( "${path.batchCompleteDir}" )
    public String batchCompleteDir;

    @Value( "${commit.hash}" )
    public String gitCommitHash;

    @Value( "${commit.date}" )
    public long gitCommitDate;

    @Value( "${version}" )
    public String version;
}
