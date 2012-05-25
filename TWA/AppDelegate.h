//
//  AppDelegate.h
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, XMPPStreamDelegate, XMPPRosterDelegate> {    
    XMPPvCardCoreDataStorage *xmppvCardStorage;
    XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    
    NSString *jidPassword;
    BOOL allowSelfSignedCertificates;
    BOOL allowSSLHostNameMismatch;
    BOOL isXMPPConnected;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

-(BOOL)connect;
-(void)disconnect;

@end
