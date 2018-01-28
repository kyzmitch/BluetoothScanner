
#import "NSString+Extension.h"

@implementation NSString (Extension)

+ (const char *)queueNameWithSuffix:(NSString *)suffix{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [[NSString stringWithFormat:@"%@.%@", bundleIdentifier, suffix] cStringUsingEncoding:NSASCIIStringEncoding];
}

@end
