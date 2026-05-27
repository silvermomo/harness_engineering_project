package com.harness.admin.util;

import javax.annotation.PostConstruct;
import lombok.Data;
import org.springframework.stereotype.Component;

import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import javax.crypto.Cipher;

@Component
@Data
public class RsaKeyUtil {

    private static final String ALGORITHM = "RSA";
    private static final String SIGNATURE_ALGORITHM = "SHA256withRSA";

    private String publicKey;
    private String privateKey;

    @PostConstruct
    public void init() throws Exception {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance(ALGORITHM);
        keyPairGenerator.initialize(2048);
        KeyPair keyPair = keyPairGenerator.generateKeyPair();

        this.publicKey = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());
        this.privateKey = Base64.getEncoder().encodeToString(keyPair.getPrivate().getEncoded());
    }

    public String decryptByPrivateKey(String encryptedText) throws Exception {
        byte[] encryptedBytes = Base64.getMimeDecoder().decode(encryptedText.replace('-', '+').replace('_', '/'));

        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(Base64.getDecoder().decode(privateKey));
        KeyFactory keyFactory = KeyFactory.getInstance(ALGORITHM);
        PrivateKey privateKeyObj = keyFactory.generatePrivate(keySpec);

        Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
        cipher.init(Cipher.DECRYPT_MODE, privateKeyObj);
        byte[] decryptedBytes = cipher.doFinal(encryptedBytes);

        return new String(decryptedBytes);
    }

    public String encryptByPublicKey(String plainText) throws Exception {
        byte[] plainBytes = plainText.getBytes();

        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(Base64.getDecoder().decode(publicKey));
        KeyFactory keyFactory = KeyFactory.getInstance(ALGORITHM);
        PublicKey publicKeyObj = keyFactory.generatePublic(keySpec);

        Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
        cipher.init(Cipher.ENCRYPT_MODE, publicKeyObj);
        byte[] encryptedBytes = cipher.doFinal(plainBytes);

        return Base64.getEncoder().encodeToString(encryptedBytes);
    }

    public boolean verifySignature(String data, String signature) throws Exception {
        byte[] signatureBytes = Base64.getDecoder().decode(signature);
        byte[] dataBytes = data.getBytes();

        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(Base64.getDecoder().decode(publicKey));
        KeyFactory keyFactory = KeyFactory.getInstance(ALGORITHM);
        PublicKey publicKeyObj = keyFactory.generatePublic(keySpec);

        Signature sig = Signature.getInstance(SIGNATURE_ALGORITHM);
        sig.initVerify(publicKeyObj);
        sig.update(dataBytes);

        return sig.verify(signatureBytes);
    }
}
