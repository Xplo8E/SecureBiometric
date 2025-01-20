# SecureBiometric App 
my super-duper secure biometric implementation with my mad skills (prompt engineering wizardry)

## How It Works 

### Secure Implementation

1. **Initialization**: 
   - The app initializes a secret message and a keychain key when it loads.
   - The `viewDidLoad` method sets up the UI and initializes secure storage.

2. **Biometric Authentication**:
   - The app uses `LAContext` to check if the device supports biometric authentication.
   - The `canEvaluatePolicy` method determines if Face ID or Touch ID is available and configured.

3. **Keychain Storage**:
   - The secret message is stored in the Keychain using `SecItemAdd`.
   - The `createAccessControl` method sets up security constraints, requiring biometric authentication to access the data.
   - The `saveToKeychain` method handles storing the data securely.

4. **Data Retrieval**:
   - When the user taps the "Authenticate" button, the app attempts to retrieve the secret message from the Keychain.
   - The `retrieveFromKeychain` method uses `SecItemCopyMatching`, which triggers a biometric prompt.
   - If authentication is successful, the secret message is displayed; otherwise, an error message is shown.

### Biometric Success and Failure

- **Success Handling**: 
  - The `SecItemCopyMatching` function is responsible for triggering the biometric prompt. 
  - If the user successfully authenticates, the function returns `errSecSuccess`, and the retrieved data is converted to a string and displayed in the UI.
  - Example Code:
    ```objc
    if (status == errSecSuccess && result != NULL) {
        NSData *resultData = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    ```

- **Failure Handling**:
  - If the biometric authentication fails, `SecItemCopyMatching` returns an error code.
  - The method then returns `nil`, and an error message is displayed to the user.
  - Example Code:
    ```objc
    if (status != errSecSuccess) {
        NSLog(@"Authentication failed with status: %d", (int)status);
        return nil;
    }
    ```

### Security Features

- **Biometric Protection**: The app requires biometric authentication to access the secret message, ensuring that only the device owner can retrieve the data.
- **Device-Specific Access**: The data is stored with `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`, meaning it can only be accessed on the device where it was stored.
- **Secure Storage**: The Keychain provides a secure way to store sensitive data, protected by the device's security features.

### Key Methods

- `setupSecureStorage`: Initializes the secure storage by checking if the secret is already stored and saving it if not.
- `saveToKeychain`: Stores the secret message in the Keychain with biometric protection.
- `retrieveFromKeychain`: Retrieves the secret message from the Keychain, triggering a biometric prompt.
- `createAccessControl`: Configures the security settings for Keychain access, requiring biometrics.

