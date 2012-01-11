package jp.archilogic.docnext.controller;

import java.text.DateFormat;
import java.util.Date;

import jp.archilogic.docnext.bean.PropBean;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class VersionController {
    @Autowired
    private PropBean prop;

    @RequestMapping( "/showVersion" )
    @ResponseBody
    public String showVersion() {
        // @formatter:off
        return "Version\n" +
                "\n" +
                "version: " + prop.version + "\n" +
                "git commit id: " + prop.gitCommitHash + "\n" +
                "git commit date: " + DateFormat.getInstance().format( new Date(prop.gitCommitDate * 1000) );
        // @formatter:on
    }
}
