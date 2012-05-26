//
//  ChatViewController.h
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TURNSocket.h"
#import "MessageDelegate.h"

@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MessageDelegate> {
    NSMutableArray *messages;
    NSMutableArray *turnSockets;
}

@property (strong, nonatomic) IBOutlet UITextField *messageTextField;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *chatBuddy;

- (IBAction)sendMessage:(id)sender;

@end
