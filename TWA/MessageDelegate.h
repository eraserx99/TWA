//
//  MessageDelegate.h
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageDelegate <NSObject>
@optional
- (void)newMessageReceived:(NSDictionary *)messageContent;
@end
