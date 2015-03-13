//
//  DNSResolve.m
//  DNSResolver
//
//  Created by Sebastian Kruschwitz on 12.03.15.
//  Copyright (c) 2015 seb. All rights reserved.
//

#import "DNSResolve.h"
@import SystemConfiguration;

#include <netdb.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#import "QCFMain.h"
#import "QCFHostResolver.h"


@implementation DNSResolve


// --- getaddrinfo ---

//http://beej.us/guide/bgnet/output/html/multipage/syscalls.html#getaddrinfo
+ (NSArray*)getaddrinfoForHost:(NSString*)host {
    
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];
    
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC; // AF_INET or AF_INET6 to force version
    hints.ai_socktype = SOCK_STREAM;
    
    if ((status = getaddrinfo([host UTF8String], "http", &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return nil;
    }
    
    NSMutableArray *resultList = [NSMutableArray array];
    
    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;
        
        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
            ipver = "IPv6";
        }
        
        // convert the IP to a string and print it:
        const char* ip = inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
        printf("  %s: %s\n", ipver, ipstr);
        
        [resultList addObject:[NSString stringWithUTF8String:ip]];
    }
    
    return resultList;
}


// --- gethostbyname ---

struct hostent* hostInfo(const char* host) {
    struct hostent *hp;
    
    const int maxtries = 5;
    int tries = 0;
    
    do {
        hp = gethostbyname(host);
        tries++;
        if (tries > maxtries) { break; }
        sleep(1);
    } while (!hp);
    
    if (!hp) {
        herror("gethostbyname(): ");
        hstrerror(h_errno);
        return NULL;
    }
    
    return hp;
}

// http://www.masterraghu.com/subjects/np/introduction/unix_network_programming_v1.3/ch11lev1sec3.html
+ (NSArray*)gethostbynameForHost:(NSString*)host {

    struct hostent *hp = hostInfo([host UTF8String]);
    
    char   **pptr;
    char   str [INET_ADDRSTRLEN];
    
    printf ("official hostname: %s\n", hp->h_name);
    
    for (pptr = hp->h_aliases; *pptr != NULL; pptr++) {
        printf ("\talias: %s\n", *pptr);
    }
    
    NSMutableArray *resultList = [NSMutableArray array];
    
    switch (hp->h_addrtype) {
         case AF_INET:
            pptr = hp->h_addr_list;
            for ( ; *pptr != NULL; pptr++) {
                const char* ip = inet_ntop (hp->h_addrtype, *pptr, str, sizeof (str));
                printf ("\tIP: %s\n", ip);
                
                [resultList addObject:[NSString stringWithUTF8String:ip]];
            }
            break;
            
        default:
            printf ("unknown address type");
            break;
    }
    
    return resultList;
}


// --- CFHost ---

//https://developer.apple.com/library/mac/samplecode/CFHostSample/Introduction/Intro.html#//apple_ref/doc/uid/DTS10003222-Intro-DontLinkElementID_2
+ (NSArray*) cfHostForHost:(NSString*)host
{
    NSMutableArray *resultList = [NSMutableArray array];
    
    Boolean result;
    CFHostRef hostRef;
    CFArrayRef addresses;
    CFStreamError error;
    hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)host);
    if (hostRef) {
        result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, &error); // pass an error instead of NULL here to find out why it failed
        if (result == TRUE) {
            
            addresses = CFHostGetAddressing(hostRef, &result);
            
            struct sockaddr_in* remoteAddr;
            
            for(int i = 0; i < CFArrayGetCount(addresses); i++)
            {
                CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
                remoteAddr = (struct sockaddr_in*)CFDataGetBytePtr(saData);
                
                if(remoteAddr != NULL)
                {
                    // Extract the ip address
                    char *inetResult = inet_ntoa(remoteAddr->sin_addr);
                    NSLog(@"INET: %s", inetResult);
                    [resultList addObject:[NSString stringWithUTF8String:inetResult]];
                }
            }
        }
        else {
            NSLog(@"Error getting Info for host: %i", error.error);
            return nil;
        }
        
    }
    else {
        NSLog(@"Error creating CFHost");
        return nil;
    }
    
    return resultList;
}


// --- VPN connected --

//http://stackoverflow.com/a/24822276/470964
+ (BOOL)isVPNConnected
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            NSString *string = [NSString stringWithFormat:@"%s" , temp_addr->ifa_name];
            if ([string rangeOfString:@"tap"].location != NSNotFound ||
                [string rangeOfString:@"tun"].location != NSNotFound ||
                [string rangeOfString:@"ppp"].location != NSNotFound){
                return YES;
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return NO;
}


// --- IP adresses ---

//http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
//http://stackoverflow.com/a/10803584/470964
+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    //NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) ) { // || (interface->ifa_flags & IFF_LOOPBACK)
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}


// --- QCFHostResolver ---

+ (void)qcfHostResolverForHost:(NSString*)host {
    
    QCFHostResolver *qcfResolver = [[QCFHostResolver alloc] initWithName:host];
    
    QCFMain *mainObj = [[QCFMain alloc] initWithResolvers:@[qcfResolver]];
    [mainObj run];
}



@end

