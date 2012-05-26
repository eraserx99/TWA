//
//  BuddyViewController.h
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface BuddyViewController : UITableViewController <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource> {
    	NSFetchedResultsController *fetchedResultsController;
}

@property (nonatomic, strong) NSString *buddyInChat;

@end
