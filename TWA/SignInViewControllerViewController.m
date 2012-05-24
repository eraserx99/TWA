//
//  SignInViewControllerViewController.m
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SignInViewControllerViewController.h"

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";

@interface SignInViewControllerViewController ()

@end

@implementation SignInViewControllerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)signIn:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}
@end
