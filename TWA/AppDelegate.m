//
//  AppDelegate.m
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "SignInViewControllerViewController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@implementation AppDelegate

@synthesize window = _window;

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSManagedObjectContext *)managedObjectContext_roster {
    return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities {
    return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

-(BOOL)connect {
    // If it is connected, do nothing!
    if(![xmppStream isDisconnected]) {
        return YES;
    }
    
    // Retrieve the JID and password from NSUserDefaults
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSString *myJIDPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
    if(myJID == nil || [myJID length] == 0 || myJIDPassword == nil || [myJIDPassword length] == 0) {
        return NO;
    }
    
    [xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    jidPassword = myJIDPassword;
    
    NSError *error = nil;
    if(![xmppStream connect:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error connecting" 
                                                                     message:@"See console for details!" 
                                                                     delegate:nil 
                                                                     cancelButtonTitle:@"OK" 
                                                                     otherButtonTitles:nil];
        [alert show];
        DDLogError(@"Error connection: %@", error);
        return NO;
    }
    
    return YES;
}

-(void)disconnect {
    [self goOffline];
    [xmppStream disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupStream {
    NSAssert(xmppStream == nil, @"setupStream is invoked multiple times!");
    
    // XMPPStream is responsbile for all XMPP activities
    // Everything else is plugged into XMPPStream
    xmppStream = [[XMPPStream alloc] init];
    
    // The simulator might have problem supporting the background applications
    // Disabling the background socket operations
    xmppStream.enableBackgroundingOnSocket = NO;
    
    // XMPPReconnect module performs the reconnection when the connection is dropped accidentally
    xmppReconnect = [[XMPPReconnect alloc] init];
    
    // XMPPRoster handls the XMPP roster.
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    xmppRoster.autoFetchRoster = YES;
    xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    // XMPPvCardAvatarModule and XMPPvCardTempModule work together to support XMPP avatars
    // XMPPRoster integrates the XMPPvCardAvatarModule to cache roster photos automatically
    xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
    // XMPPCapabilities handles XEP-0115
    xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    // Activating the modules
    [xmppReconnect activate:xmppStream];
    [xmppRoster activate:xmppStream];
    [xmppvCardTempModule activate:xmppStream];
    [xmppvCardAvatarModule activate:xmppStream];
    [xmppCapabilities activate:xmppStream];
    
    // Make myself as the deletege for XMPPStream and XMPPRoster
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    allowSelfSignedCertificates = YES;
    allowSSLHostNameMismatch = YES;
}

-(void)teardownStream {
    // Remove myself from XMPPRoster and XMPPStream
    [xmppRoster removeDelegate:self];
    [xmppStream removeDelegate:self];
    
    // Deactivate modules
    [xmppCapabilities deactivate];
    [xmppvCardAvatarModule deactivate];
    [xmppvCardTempModule deactivate];
    [xmppRoster deactivate];
    [xmppReconnect deactivate];
    
    // Disconnect from the server
    [xmppStream disconnect];
    
    xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

-(void)goOnline {
    // Prepare and send presence (available) packet
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}

-(void)goOffline {
    // Prepare and send presence (unavailable) packet
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

@end
