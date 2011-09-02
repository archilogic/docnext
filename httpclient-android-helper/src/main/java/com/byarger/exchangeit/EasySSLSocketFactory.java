package com.byarger.exchangeit;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.UnknownHostException;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;

import org.apache.http.conn.ConnectTimeoutException;
import org.apache.http.conn.scheme.LayeredSocketFactory;
import org.apache.http.conn.scheme.SocketFactory;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;

/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/**
 * This socket factory will create ssl socket that accepts self signed certificate
 * 
 * @author olamy
 * @version $Id: EasySSLSocketFactory.java 765355 2009-04-15 20:59:07Z evenisse $
 * @since 1.2.3
 */
public class EasySSLSocketFactory implements SocketFactory , LayeredSocketFactory {

    private static SSLContext createEasySSLContext() throws IOException {
        try {
            final SSLContext context = SSLContext.getInstance( "TLS" );
            context.init( null , new TrustManager[] { new EasyX509TrustManager( null ) } , null );
            return context;
        } catch ( final Exception e ) {
            throw new IOException( e.getMessage() );
        }
    }

    private SSLContext sslcontext = null;

    /**
     * @see org.apache.http.conn.scheme.SocketFactory#connectSocket(java.net.Socket, java.lang.String, int,
     *      java.net.InetAddress, int, org.apache.http.params.HttpParams)
     */
    @Override
    public Socket connectSocket( final Socket sock , final String host , final int port , final InetAddress localAddress , int localPort ,
            final HttpParams params ) throws IOException , UnknownHostException , ConnectTimeoutException {
        final int connTimeout = HttpConnectionParams.getConnectionTimeout( params );
        final int soTimeout = HttpConnectionParams.getSoTimeout( params );

        final InetSocketAddress remoteAddress = new InetSocketAddress( host , port );
        final SSLSocket sslsock = ( SSLSocket ) ( sock != null ? sock : createSocket() );

        if ( localAddress != null || localPort > 0 ) {
            // we need to bind explicitly
            if ( localPort < 0 ) {
                localPort = 0; // indicates "any"
            }
            final InetSocketAddress isa = new InetSocketAddress( localAddress , localPort );
            sslsock.bind( isa );
        }

        sslsock.connect( remoteAddress , connTimeout );
        sslsock.setSoTimeout( soTimeout );
        return sslsock;

    }

    /**
     * @see org.apache.http.conn.scheme.SocketFactory#createSocket()
     */
    @Override
    public Socket createSocket() throws IOException {
        return getSSLContext().getSocketFactory().createSocket();
    }

    /**
     * @see org.apache.http.conn.scheme.LayeredSocketFactory#createSocket(java.net.Socket, java.lang.String, int,
     *      boolean)
     */
    @Override
    public Socket createSocket( final Socket socket , final String host , final int port , final boolean autoClose ) throws IOException ,
            UnknownHostException {
        return getSSLContext().getSocketFactory().createSocket( socket , host , port , autoClose );
    }

    @Override
    public boolean equals( final Object obj ) {
        return obj != null && obj.getClass().equals( EasySSLSocketFactory.class );
    }

    private SSLContext getSSLContext() throws IOException {
        if ( this.sslcontext == null ) {
            this.sslcontext = createEasySSLContext();
        }
        return this.sslcontext;
    }

    // -------------------------------------------------------------------
    // javadoc in org.apache.http.conn.scheme.SocketFactory says :
    // Both Object.equals() and Object.hashCode() must be overridden
    // for the correct operation of some connection managers
    // -------------------------------------------------------------------

    @Override
    public int hashCode() {
        return EasySSLSocketFactory.class.hashCode();
    }

    /**
     * @see org.apache.http.conn.scheme.SocketFactory#isSecure(java.net.Socket)
     */
    @Override
    public boolean isSecure( final Socket socket ) throws IllegalArgumentException {
        return true;
    }

}
