package jp.archilogic.docnext.advisor;

import java.lang.reflect.Method;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.aop.MethodBeforeAdvice;
import org.springframework.stereotype.Component;

@Component
public class MethodNameTraceAdvisor implements MethodBeforeAdvice {
    private static final Logger LOGGER = LoggerFactory.getLogger( MethodNameTraceAdvisor.class );

    @Override
    public void before( Method method , Object[] args , Object target ) throws Throwable {
        LOGGER.info( "Invoke " + method.toString() );
    }
}
