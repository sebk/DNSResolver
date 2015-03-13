
// Copied from https://developer.apple.com/library/mac/samplecode/CFHostSample/Introduction/Intro.html

#import <Foundation/Foundation.h>

@interface QCFMain : NSObject

- (id)initWithResolvers:(NSArray *)resolvers;

@property (nonatomic, copy,   readonly ) NSArray *      resolvers;

- (void)run;

@end
