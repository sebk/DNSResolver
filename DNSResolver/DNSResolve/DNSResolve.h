//
//  DNSResolve.h
//  DNSResolver
//
//  Created by Sebastian Kruschwitz on 12.03.15.
//  Copyright (c) 2015 seb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNSResolve : NSObject

+ (NSArray*)getaddrinfoForHost:(NSString*)host;

+ (NSArray*)gethostbynameForHost:(NSString*)host;

+ (NSArray*) cfHostForHost:(NSString*)host;

+ (BOOL)isVPNConnected;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;

+ (void)qcfHostResolverForHost:(NSString*)host;

@end
