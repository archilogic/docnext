package jp.archilogic.docnext.android.drm;

import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.SecretKeySpec;

public class Blowfish {
    static String algorithm = "DES";
    public static SecretKeySpec skeySpec;
    
    public static SecretKeySpec getSecretKeySpec() {
        @SuppressWarnings("unused")
        byte[] raw = { 
                0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
                0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
                0x10, 0x10, 0x10, 0x10
        };


        byte[] rawForDES = { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x20 }; 
        return skeySpec = new SecretKeySpec( rawForDES , algorithm );
        //return skeySpec = new SecretKeySpec( raw, algorithm);
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
