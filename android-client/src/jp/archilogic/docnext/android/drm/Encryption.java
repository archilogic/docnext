package jp.archilogic.docnext.android.drm;

import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.SecretKeySpec;

public class Encryption {
    static String algorithm = "DES";
    public static SecretKeySpec skeySpec;
    
    public static SecretKeySpec getSecretKeySpec() {
        int keyLength = 0;
        try {
            KeyGenerator generator = KeyGenerator.getInstance( algorithm );
            keyLength = generator.generateKey().getEncoded().length;
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        
        byte[] raw = "1234567812345678".getBytes();
        byte[] fitting = new byte[keyLength];
        for ( int i = 0 ; i < fitting.length ; i++ ) {
            fitting[ i ] = raw[ i ];
        }
        
        return skeySpec = new SecretKeySpec( fitting , algorithm );
    }
    
    public static Cipher getInstance() {
        try {
            return Cipher.getInstance(algorithm);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            throw new RuntimeException();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
            throw new RuntimeException();
        }
    }
    
    public static Cipher getDecryptor() {
        Cipher c = getInstance();
        try {
            c.init(Cipher.DECRYPT_MODE , getSecretKeySpec() );
        } catch (InvalidKeyException e) {
            e.printStackTrace();
            throw new RuntimeException();
        } 
        return c;
    }
    
    public static Cipher getEncryptor() {
        Cipher c = getInstance();
        try {
            c.init(Cipher.ENCRYPT_MODE , getSecretKeySpec() );
        } catch (InvalidKeyException e) {
            e.printStackTrace();
            throw new RuntimeException();
        } 
        return c;
    }
}
