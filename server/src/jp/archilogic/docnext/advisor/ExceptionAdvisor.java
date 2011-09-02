package jp.archilogic.docnext.advisor;

import org.springframework.aop.ThrowsAdvice;
import org.springframework.stereotype.Component;

@Component
public class ExceptionAdvisor implements ThrowsAdvice {
    public void afterThrowing( Throwable thrown ) throws Throwable {
        thrown.printStackTrace();
    }
}
