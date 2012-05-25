//
//  SignInViewController.h
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyPassword;

@interface SignInViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *jidTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)signIn:(id)sender;
@end
