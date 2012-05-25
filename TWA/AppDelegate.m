//
//  AppDelegate.m
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "SignInViewController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface AppDelegate ()

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

@end

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
    
    // Configure logging framework
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Setup the XMPP framework
    [self setupStream];
    
    // Connect......
    [self connect];
    
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * This method is called before the stream begins the connection process.
 *
 * If developing an iOS app that runs in the background, this may be a good place to indicate
 * that this is a task that needs to continue running in the background.
 **/
- (void)xmppStreamWillConnect:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}

/**
 * This method is called after the tcp socket has connected to the remote host.
 * It may be used as a hook for various things, such as updating the UI or extracting the server's IP address.
 * 
 * If developing an iOS app that runs in the background,
 * please use XMPPStream's enableBackgroundingOnSocket property as opposed to doing it directly on the socket here.
 **/
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}

/**
 * This method is called after a TCP connection has been established with the server,
 * and the opening XML stream negotiation has started.
 **/
- (void)xmppStreamDidStartNegotiation:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}

/**
 * This method is called immediately prior to the stream being secured via TLS/SSL.
 * Note that this delegate may be called even if you do not explicitly invoke the startTLS method.
 * Servers have the option of requiring connections to be secured during the opening process.
 * If this is the case, the XMPPStream will automatically attempt to properly secure the connection.
 * 
 * The possible keys and values for the security settings are well documented.
 * Some possible keys are:
 * - kCFStreamSSLLevel
 * - kCFStreamSSLAllowsExpiredCertificates
 * - kCFStreamSSLAllowsExpiredRoots
 * - kCFStreamSSLAllowsAnyRoot
 * - kCFStreamSSLValidatesCertificateChain
 * - kCFStreamSSLPeerName
 * - kCFStreamSSLCertificates
 * 
 * Please refer to Apple's documentation for associated values, as well as other possible keys.
 * 
 * The dictionary of settings is what will be passed to the startTLS method of ther underlying AsyncSocket.
 * The AsyncSocket header file also contains a discussion of the security consequences of various options.
 * It is recommended reading if you are planning on implementing this method.
 * 
 * The dictionary of settings that are initially passed will be an empty dictionary.
 * If you choose not to implement this method, or simply do not edit the dictionary,
 * then the default settings will be used.
 * That is, the kCFStreamSSLPeerName will be set to the configured host name,
 * and the default security validation checks will be performed.
 * 
 * This means that authentication will fail if the name on the X509 certificate of
 * the server does not match the value of the hostname for the xmpp stream.
 * It will also fail if the certificate is self-signed, or if it is expired, etc.
 * 
 * These settings are most likely the right fit for most production environments,
 * but may need to be tweaked for development or testing,
 * where the development server may be using a self-signed certificate.
 **/
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(allowSelfSignedCertificates) {
        [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    }
    
    if(allowSSLHostNameMismatch) {
        [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
    }
}

/**
 * This method is called after the stream has been secured via SSL/TLS.
 * This method may be called if the server required a secure connection during the opening process,
 * or if the secureConnection: method was manually invoked.
 **/
- (void)xmppStreamDidSecure:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called after the XML stream has been fully opened.
 * More precisely, this method is called after an opening <xml/> and <stream:stream/> tag have been sent and received,
 * and after the stream features have been received, and any required features have been fullfilled.
 * At this point it's safe to begin communication with the server.
 **/
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    isXMPPConnected = YES;
    
    NSError *error = nil;
    
    if(![[self xmppStream] authenticateWithPassword:jidPassword error:&error]) {
        DDLogError(@"Error authenticating %@", error);
    }
}

/**
 * This method is called after registration of a new user has successfully finished.
 * If registration fails for some reason, the xmppStream:didNotRegister: method will be called instead.
 **/
- (void)xmppStreamDidRegister:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called if registration fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called after authentication has successfully finished.
 * If authentication fails for some reason, the xmppStream:didNotAuthenticate: method will be called instead.
 **/
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [self goOnline];
}

/**
 * This method is called if authentication fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called if the XMPP server doesn't allow our resource of choice
 * because it conflicts with an existing resource.
 * 
 * Return an alternative resource or return nil to let the server automatically pick a resource for us.
 **/
- (NSString *)xmppStream:(XMPPStream *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource {
    return nil;
}

/**
 * These methods are called after their respective XML elements are received on the stream.
 * 
 * In the case of an IQ, the delegate method should return YES if it has or will respond to the given IQ.
 * If the IQ is of type 'get' or 'set', and no delegates respond to the IQ,
 * then xmpp stream will automatically send an error response.
 **/
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
 	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called if an XMPP error is received.
 * In other words, a <stream:error/>.
 * 
 * However, this method may also be called for any unrecognized xml stanzas.
 * 
 * Note that standard errors (<iq type='error'/> for example) are delivered normally,
 * via the other didReceive...: methods.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * These methods are called before their respective XML elements are sent over the stream.
 * These methods can be used to customize elements on the fly.
 * (E.g. add standard information for custom protocols.)
 **/
- (void)xmppStream:(XMPPStream *)sender willSendIQ:(XMPPIQ *)iq {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * These methods are called after their respective XML elements are sent over the stream.
 * These methods may be used to listen for certain events (such as an unavailable presence having been sent),
 * or for general logging purposes. (E.g. a central history logging mechanism).
 **/
- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called if the disconnect method is called.
 * It may be used to determine if a disconnection was purposeful, or due to an error.
 **/
- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is called after the stream is closed.
 * 
 * The given error parameter will be non-nil if the error was due to something outside the general xmpp realm.
 * Some examples:
 * - The TCP socket was unexpectedly disconnected.
 * - The SRV resolution of the domain failed.
 * - Error parsing xml sent from server. 
 **/
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if(!isXMPPConnected) {
        DDLogError(@"Unable to connect to the XMPP Server");
    }
}

/**
 * This method is only used in P2P mode when the connectTo:withAddress: method was used.
 * 
 * It allows the delegate to read the <stream:features/> element if/when they arrive.
 * Recall that the XEP specifies that <stream:features/> SHOULD be sent.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * This method is only used in P2P mode when the connectTo:withSocket: method was used.
 * 
 * It allows the delegate to customize the <stream:features/> element,
 * adding any specific featues the delegate might support.
 **/
- (void)xmppStream:(XMPPStream *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

/**
 * These methods are called as xmpp modules are registered and unregistered with the stream.
 * This generally corresponds to xmpp modules being initailzed and deallocated.
 * 
 * The methods may be useful, for example, if a more precise auto delegation mechanism is needed
 * than what is available with the autoAddDelegate:toModulesOfClass: method.
 **/
- (void)xmppStream:(XMPPStream *)sender didRegisterModule:(id)module {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willUnregisterModule:(id)module {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRoster Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Sent when a presence subscription request is received.
 * That is, another user has added you to their roster,
 * and is requesting permission to receive presence broadcasts that you send.
 * 
 * The entire presence packet is provided for proper extensibility.
 * You can use [presence from] to get the JID of the user who sent the request.
 * 
 * The methods acceptPresenceSubscriptionRequestFrom: and rejectPresenceSubscriptionRequestFrom: can
 * be used to respond to the request.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
