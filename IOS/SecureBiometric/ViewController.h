//
//  ViewController.h
//  SecureBiometric
//
//  Created by APPLE on 12/11/24.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *authenticateButton;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
- (IBAction)authenticateButtonTapped:(id)sender;


@end

