//
//  QCFMain.m
//  DNSResolver
//
//  Created by Sebastian Kruschwitz on 12.03.15.
//  Copyright (c) 2015 seb. All rights reserved.
//

#import "QCFMain.h"
#import "QCFHostResolver.h"

@interface QCFMain () <QCFHostResolverDelegate>

@property (nonatomic, assign, readwrite) NSUInteger     runningResolverCount;

@end

@implementation QCFMain

@synthesize resolvers = _resolvers;

@synthesize runningResolverCount = _runningResolverCount;

- (id)initWithResolvers:(NSArray *)resolvers
{
    self = [super init];
    if (self != nil) {
        self->_resolvers = [resolvers copy];
    }
    return self;
}

- (void)run
{
    self.runningResolverCount = [self.resolvers count];
    
    // Start each of the resolvers.
    
    for (QCFHostResolver * resolver in self.resolvers) {
        resolver.delegate = self;
        [resolver start];
    }
    
    // Run the run loop until they are all done.
    
    while (self.runningResolverCount != 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)hostResolverDidFinish:(QCFHostResolver *)resolver
// A resolver delegate callback, called when the resolve completes successfully.
// Prints the results.
{
    NSString *      argument;
    NSString *      result;
    
    if (resolver.name != nil) {
        argument = resolver.name;
        result   = [resolver.resolvedAddressStrings componentsJoinedByString:@", "];
    } else {
        argument = resolver.addressString;
        result   = [resolver.resolvedNames componentsJoinedByString:@", "];
    }
    fprintf(stderr, "%s -> %s\n", [argument UTF8String], [result UTF8String]);
    self.runningResolverCount -= 1;
}

- (void)hostResolver:(QCFHostResolver *)resolver didFailWithError:(NSError *)error
// A resolver delegate callback, called when the resolve fails.  Prints the error.
{
    NSString *      argument;
    
    if (resolver.name != nil) {
        argument = resolver.name;
    } else {
        argument = resolver.addressString;
    }
    fprintf(stderr, "%s -> %s / %zd\n", [argument UTF8String], [[error domain] UTF8String], (ssize_t) [error code]);
    self.runningResolverCount -= 1;
}


@end
