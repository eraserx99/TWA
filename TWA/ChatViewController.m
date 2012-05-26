//
//  ChatViewController.m
//  TWA
//
//  Created by CHIH-CHUN CHIEN on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"
#import "AppDelegate.h"
#import "NSString+Utils.h"
#import "XMPP.h"
#import "DDXML.h"

@interface ChatViewController ()

@end

@implementation ChatViewController
@synthesize messageTextField;
@synthesize tableView;
@synthesize chatBuddy;

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
    
	// Do any additional setup after loading the view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [[self appDelegate] setMessageDelegate:self];
    [self.messageTextField becomeFirstResponder];
    
    messages = [[NSMutableArray alloc] init];
    turnSockets = [[NSMutableArray alloc] init];
    
    XMPPJID *jid = [XMPPJID jidWithString:@"cesare@YOURSERVER"];
    TURNSocket *ts = [[TURNSocket alloc] initWithStream:[[self appDelegate] xmppStream] toJID:jid];
    [turnSockets addObject:ts];
    [ts startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)viewDidUnload
{
    [self setMessageTextField:nil];
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)sendMessage:(id)sender {
    NSString *messageStr = self.messageTextField.text;
    
    if(messageStr != nil && [messageStr length] > 0) {
        // Compose the XMPP XML message
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:chatBuddy];
        [message addChild:body];
        
        // Deliver the XMPP message
        [[[self appDelegate] xmppStream] sendElement:message];
        
        self.messageTextField.text = @"";
        
        NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
        [m setObject:messageStr forKey:@"msg"];
        [m setObject:@"you" forKey:@"sender"];
        [m setObject:[NSString now] forKey:@"time"];
        
        [messages addObject:m];
        [self.tableView reloadData];
    }
    
    // Scroll the table view contents properly
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count -1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:topIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Helpers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark MessageDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)newMessageReceived:(NSDictionary *)messageContent {
    // Add the received message to the messages array and reload the table view
    [messages addObject:messageContent];
    [self.tableView reloadData];
    
    // Scroll the table view contents properly
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count -1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:topIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Finish and Cleanup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)turnSocket:(TURNSocket *)sender didSucceed:(GCDAsyncSocket *)socket {
	[turnSockets removeObject:sender];
}

- (void)turnSocketDidFail:(TURNSocket *)sender {
	[turnSockets removeObject:sender];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDataSource
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    return [messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *s = (NSDictionary *)[messages objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"myChat";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *sender = [s objectForKey:@"sender"];
    NSString *message = [s objectForKey:@"msg"];
    NSString *time = [s objectForKey:@"time"];
    
    cell.textLabel.text = message;
    cell.detailTextLabel.text = [[sender stringByAppendingString:@"@"] stringByAppendingString:time];

    return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
}

@end
