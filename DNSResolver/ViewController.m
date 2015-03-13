//
//  ViewController.m
//  DNSResolver
//
//  Created by Sebastian Kruschwitz on 10.03.15.
//  Copyright (c) 2015 seb. All rights reserved.
//

#import "ViewController.h"
#import "DNSResolve.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    [DNSResolve getaddrinfoForHost:@"www.google.de"];
    
    [DNSResolve gethostbynameForHost:@"www.google.de"];
    
    [DNSResolve cfHostForHost:@"www.google.de"];
    
    if([DNSResolve isVPNConnected]) {
        NSLog(@"VPN connected");
    }
    else {
        NSLog(@"VPN not connected");
    }
    
    NSLog(@"%@", [DNSResolve getIPAddress:YES]);
    
    NSLog(@"%@", [DNSResolve getIPAddresses]);
    
    [DNSResolve qcfHostResolverForHost:@"www.google.de"];

}

@end
