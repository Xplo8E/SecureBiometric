//
//  ViewController.m
//  SecureBiometric
//
//  Created by APPLE on 12/11/24.
//

#import "ViewController.h"

@interface ViewController ()
// Keys for storing and retrieving secure data
@property (nonatomic, strong) NSString *keychainKey;
@property (nonatomic, strong) NSString *secretMessage;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize keys and secret message
    self.keychainKey = @"com.yourapp.biometric.key";
    self.secretMessage = @"sup3r_s3cur3_k3y";
    
    // UI Setup
    [self setupUI];
    
    // Initialize secure storage on first launch
    [self setupSecureStorage];
}

- (void)setupUI {
    // Basic UI configuration
    self.view.backgroundColor = UIColor.whiteColor;
    
    // Configure result label
    self.resultLabel.text = @"Authenticate to see message";
    self.resultLabel.textColor = UIColor.blackColor;
    self.resultLabel.font = [UIFont boldSystemFontOfSize:20.0];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    
    // Configure authenticate button
    [self.authenticateButton setTitle:@"Authenticate" forState:UIControlStateNormal];
    [self.authenticateButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.authenticateButton.backgroundColor = [UIColor systemBlueColor];
    self.authenticateButton.layer.cornerRadius = 10.0;
}

- (void)setupSecureStorage {
    // Add logging to debug
    NSLog(@"Setting up secure storage");
    
    // Check if secret is already stored in keychain
    if (![self retrieveFromKeychain]) {
        NSLog(@"No existing secret found, attempting to save");
        // If not found, store it securely
        BOOL savedSuccessfully = [self saveToKeychain:self.secretMessage];
        NSLog(@"Save attempt result: %@", savedSuccessfully ? @"Success" : @"Failed");
    }
}

- (BOOL)saveToKeychain:(NSString *)secret {
    // Create LAContext for biometric authentication
    LAContext *context = [[LAContext alloc] init];
    context.interactionNotAllowed = YES; // Allow UI interaction
    context.localizedReason = @"Authenticate to save secure message"; // Set authentication reason
    
    // Convert string to data for storage
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    
    // First, try to delete any existing item
    NSDictionary *deleteQuery = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: self.keychainKey,
    };
    SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    
    // Setup keychain query with security attributes
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,        // Specify type of keychain item
        (__bridge id)kSecAttrAccount: self.keychainKey,                       // Unique identifier for the item
        (__bridge id)kSecValueData: secretData,                               // The actual data to store
        (__bridge id)kSecAttrAccessControl: [self createAccessControl],       // Security controls (biometric)
        // (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIAllow  // Allow biometric UI (Deprecated in iOS 14.0)
        (__bridge id)kSecUseAuthenticationContext: context                    // Modern approach for biometric UI
    };
    
    // Attempt to add item to keychain
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
    NSLog(@"Save to keychain status: %d", (int)status);
    
    return status == errSecSuccess;
}

- (NSString *)retrieveFromKeychain {
    // Create LAContext for biometric authentication
    LAContext *context = [[LAContext alloc] init];
    context.interactionNotAllowed = NO; // Allow UI interaction
    context.localizedReason = @"Authenticate to access the secure message"; // Set authentication reason
    
    // Setup query to retrieve the secure item
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,        // Type of keychain item
        (__bridge id)kSecAttrAccount: self.keychainKey,                       // Identifier to find item
        (__bridge id)kSecReturnData: @YES,                                    // Request the actual data
        // (__bridge id)kSecUseOperationPrompt: @"Authenticate to access the secure message",  // Message shown to user (Deprecated in iOS 14.0)
        // (__bridge id)kSecUseAuthenticationUI: (__bridge id)kSecUseAuthenticationUIAllow    // Allow biometric UI (Deprecated in iOS 14.0)
        (__bridge id)kSecUseAuthenticationContext: context                    // Modern approach for biometric UI
    };
    
    // Attempt to retrieve the item
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    // This function triggers the biometric prompt when accessing the keychain item.
    // If the user successfully authenticates using biometrics, the function returns errSecSuccess,
    // and the retrieved data is converted to a string. If authentication fails, it returns an error,
    // and the method returns nil, indicating the retrieval was unsuccessful.
    NSLog(@"Keychain retrieval status: %d", (int)status);
    
    // If successful, convert result to string
    if (status == errSecSuccess && result != NULL) {
        NSData *resultData = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (id)createAccessControl {
    // Create access control with specific security requirements
    CFErrorRef error = NULL;
    SecAccessControlRef access = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,  // Only accessible when device is unlocked
        kSecAccessControlBiometryAny,                     // Require biometric authentication
        &error);
    
    if (error != NULL) {
        NSLog(@"Failed to create access control: %@", error);
        return nil;
    }
    
    return (__bridge_transfer id)access;
}

- (IBAction)authenticateButtonTapped:(id)sender {

     /* 
    // VULNERABLE IMPLEMENTATION - Easily bypassed through runtime manipulation
    // It was vulnerable to runtime manipulation and didn't use secure storage
    // 1. Create LAContext instance
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    
    // 2. Check if device can use biometric authentication
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        
        // 3. Request biometric authentication
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:@"Authenticate to see the message"
                        reply:^(BOOL success, NSError *error) {
            
            // 4. Handle the authentication result
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    self.resultLabel.text = @"Hello World!";
                } else {
                    self.resultLabel.text = @"Authentication failed";
                }
            });
        }];
    } else {
        // 5. Handle devices without biometric capability
        self.resultLabel.text = @"Biometric authentication not available";
    }
    */
    
    // SECURE IMPLEMENTATION
    // First check if device can use biometrics
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        context.localizedReason = @"Authenticate to access the secure message";
        
        // Use dispatch_sync for keychain operations to ensure sequential execution
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // First ensure the secret is stored
            if (![self retrieveFromKeychain]) {
                BOOL saved = [self saveToKeychain:self.secretMessage];
                if (!saved) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.resultLabel.text = @"Failed to setup secure storage";
                    });
                    return;
                }
            }
            
            // Now try to retrieve it
            NSString *retrievedMessage = [self retrieveFromKeychain];
            
            // Update UI on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if (retrievedMessage) {
                    self.resultLabel.text = retrievedMessage;
                } else {
                    self.resultLabel.text = @"Authentication failed";
                }
            });
        });
    } else {
        // Handle the case where biometrics are not available
        self.resultLabel.text = [NSString stringWithFormat:@"Biometrics not available: %@", error.localizedDescription];
        NSLog(@"Biometrics not available: %@", error);
    }
}

@end

