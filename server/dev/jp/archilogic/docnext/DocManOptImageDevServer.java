package jp.archilogic.docnext;

import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.bio.SocketConnector;
import org.eclipse.jetty.webapp.WebAppContext;

public class DocManOptImageDevServer {
    public static void main( String[] args ) throws Exception {
        Server server = new Server();

        SocketConnector connector = new SocketConnector();
        connector.setPort( 8888 );
        server.setConnectors( new Connector[] { connector } );

        WebAppContext handler = new WebAppContext( "war" , "/" );
        handler.setClassLoader( DocManOptImageDevServer.class.getClassLoader() );
        server.setHandler( handler );

        server.start();
    }
}
