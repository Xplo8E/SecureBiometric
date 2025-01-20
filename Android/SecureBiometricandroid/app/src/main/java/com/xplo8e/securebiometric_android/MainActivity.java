package com.xplo8e.securebiometric_android;

import android.os.Bundle;
import android.content.Intent;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Log;
import android.widget.Toast;

import java.security.KeyStore;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.util.concurrent.Executor;
import javax.crypto.spec.IvParameterSpec;
import androidx.biometric.BiometricManager;
import java.security.NoSuchAlgorithmException;
import javax.crypto.NoSuchPaddingException;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "SecureBiometric";
    private static final String KEY_NAME = "biometric_secure_key";
    private static final String SAMPLE_SECRET = "Secret : This is a s3cr3t message that needs encryption";
    private byte[] encryptedData;
    private byte[] initializationVector;
    private BiometricPrompt biometricPrompt;
    private BiometricPrompt.PromptInfo promptInfo;
    private Executor executor;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Step 1: Generate secure key and setup biometric
        Log.d(TAG, "Setting up biometric authentication components...");
        setupBiometricAuthentication();
        generateSecretKey();
        
        findViewById(R.id.authenticateButton).setOnClickListener(v -> {
            Log.d(TAG, "Authentication button clicked");
            authenticateToEncrypt();
        });
    }

    /**
     * Step 1: Generate a secure key in the Android Keystore
     * - Requires user authentication for every use (timeout = 0)
     * - Invalidates key if new biometrics are enrolled
     * - Uses strong authentication parameters
     */
    private void generateSecretKey() {
        try {
            Log.d(TAG, "Generating secure key in Android Keystore...");
            KeyGenParameterSpec.Builder builder = new KeyGenParameterSpec.Builder(
                    KEY_NAME,
                    KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_CBC)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7)
                    .setUserAuthenticationRequired(true)  // Require user authentication
                    .setInvalidatedByBiometricEnrollment(true);  // Invalidate on new biometric enrollment

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                // For Android 11+: Set authentication timeout to 0 (require auth for every use)
                builder.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG);
            } else {
                // For older versions: Use validity duration of -1 (require auth for every use)
                builder.setUserAuthenticationValidityDurationSeconds(-1);
            }

            KeyGenerator keyGenerator = KeyGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            keyGenerator.init(builder.build());
            keyGenerator.generateKey();
            Log.d(TAG, "Secure key generated successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error generating secure key: " + e.getMessage());
            showError("Error generating key: " + e.getMessage());
        }
    }

    /**
     * Step 2 & 3: Initialize cipher and create CryptoObject
     * - Gets the cipher instance
     * - Initializes it with the secure key
     * - Creates BiometricPrompt.CryptoObject
     */
    private void authenticateToEncrypt() {
        try {
            Log.d(TAG, "Setting up cipher for biometric authentication...");
            
            // Step 2: Initialize cipher
            Cipher cipher = getCipher();
            if (cipher == null) {
                showError("Failed to get cipher instance");
                return;
            }

            SecretKey secretKey = getSecretKey();
            if (secretKey == null) {
                showError("Secret key not found");
                return;
            }

            // Initialize cipher based on operation mode
            if (encryptedData == null) {
                cipher.init(Cipher.ENCRYPT_MODE, secretKey);
                initializationVector = cipher.getIV();
                Log.d(TAG, "Cipher initialized for encryption");
            } else {
                cipher.init(Cipher.DECRYPT_MODE, secretKey, new IvParameterSpec(initializationVector));
                Log.d(TAG, "Cipher initialized for decryption");
            }
            
            // Step 3: Create CryptoObject
            BiometricPrompt.CryptoObject cryptoObject = new BiometricPrompt.CryptoObject(cipher);
            Log.d(TAG, "CryptoObject created, triggering biometric prompt");
            
            // Step 5: Call authenticate with CryptoObject
            biometricPrompt.authenticate(promptInfo, cryptoObject);
        } catch (Exception e) {
            Log.e(TAG, "Authentication setup failed: " + e.getMessage());
            showError("Authentication setup failed: " + e.getMessage());
        }
    }

    /**
     * Sets up the BiometricPrompt with authentication callbacks
     * Step 4: Implement authentication callbacks
     */
    private void setupBiometricAuthentication() {
        executor = ContextCompat.getMainExecutor(this);
        biometricPrompt = new BiometricPrompt(this, executor,
                new BiometricPrompt.AuthenticationCallback() {
            @Override
            public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                super.onAuthenticationSucceeded(result);
                Log.d(TAG, "Biometric authentication succeeded");
                
                try {
                    // Get authenticated cipher from crypto object
                    Cipher cipher = result.getCryptoObject().getCipher();
                    if (encryptedData == null) {
                        // First time: perform encryption
                        encryptedData = cipher.doFinal(SAMPLE_SECRET.getBytes());
                        Log.d(TAG, "Data encrypted successfully");
                        showSecretContent(SAMPLE_SECRET);
                    } else {
                        // Subsequent times: perform decryption
                        byte[] decryptedData = cipher.doFinal(encryptedData);
                        String decryptedString = new String(decryptedData);
                        Log.d(TAG, "Data decrypted successfully");
                        showSecretContent(decryptedString);
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Encryption/Decryption failed: " + e.getMessage());
                    showError("Encryption/Decryption failed: " + e.getMessage());
                }
            }

            @Override
            public void onAuthenticationError(int errorCode, CharSequence errString) {
                super.onAuthenticationError(errorCode, errString);
                if (errorCode != BiometricPrompt.ERROR_CANCELED && 
                    errorCode != BiometricPrompt.ERROR_USER_CANCELED && 
                    errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON) {
                    Log.e(TAG, "Authentication error [" + errorCode + "]: " + errString);
                    showError("Authentication error: " + errString);
                }
            }

            @Override
            public void onAuthenticationFailed() {
                super.onAuthenticationFailed();
                Log.d(TAG, "Authentication failed");
            }
        });

        promptInfo = new BiometricPrompt.PromptInfo.Builder()
                .setTitle("Biometric Authentication")
                .setSubtitle("Log in using your biometric credential")
                .setNegativeButtonText("Cancel")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .setConfirmationRequired(false)
                .build();
        
        Log.d(TAG, "Biometric prompt setup completed");
    }

    // Helper methods
    private SecretKey getSecretKey() {
        try {
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);
            return ((SecretKey) keyStore.getKey(KEY_NAME, null));
        } catch (Exception e) {
            Log.e(TAG, "Error getting secret key: " + e.getMessage());
            return null;
        }
    }

    private Cipher getCipher() {
        try {
            String transformation = 
                KeyProperties.KEY_ALGORITHM_AES + "/" +
                KeyProperties.BLOCK_MODE_CBC + "/" +
                KeyProperties.ENCRYPTION_PADDING_PKCS7;
            return Cipher.getInstance(transformation);
        } catch (Exception e) {
            Log.e(TAG, "Error getting cipher: " + e.getMessage());
            return null;
        }
    }

    private void showSecretContent(String decryptedMessage) {
        Log.d(TAG, "Launching SecretActivity with decrypted message");
        Intent intent = new Intent(this, SecretActivity.class);
        intent.putExtra("SECRET_MESSAGE", decryptedMessage);
        startActivity(intent);
    }

    private void showError(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        Log.e(TAG, message);
    }
}