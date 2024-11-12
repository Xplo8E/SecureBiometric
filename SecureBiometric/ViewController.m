//
//  ViewController.m
//  SecureBiometric
//
//  Created by APPLE on 12/11/24.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure view
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

- (IBAction)authenticateButtonTapped:(id)sender {
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
}

@end
