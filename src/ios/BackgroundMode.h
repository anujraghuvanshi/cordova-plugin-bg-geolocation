#import <Cordova/CDVPlugin.h>
#import <CoreLocation/CoreLocation.h>

enum CDVLocationStatus {
    PERMISSIONDENIED = 1
};

@interface BackgroundMode : CDVPlugin <CLLocationManagerDelegate>  {}
- (void) sendPluginResult: (CDVPluginResult*)result :(CDVInvokedUrlCommand*)command;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSTimer *lastLocationUpdateTimer;
// Activate the background mode

- (void) startGettingBackgroundLocation:(CDVInvokedUrlCommand*)command;
- (void) checkUpdates:(NSTimer *)timer;

@end
