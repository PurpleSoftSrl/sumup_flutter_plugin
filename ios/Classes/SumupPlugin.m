#import "SumupPlugin.h"
#if __has_include(<sumup/sumup-Swift.h>)
#import <sumup/sumup-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "sumup-Swift.h"
#endif

@implementation SumupPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSumupPlugin registerWithRegistrar:registrar];
}
@end
