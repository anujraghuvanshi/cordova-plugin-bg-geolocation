#import "BackgroundMode.h"
#import <Cordova/CDVAvailability.h>

@implementation BackgroundMode

/************************************************************/
#pragma mark - Stores Plugin Command
/************************************************************/

CDVInvokedUrlCommand* pluginCommand;

/****************************************************/
#pragma mark - PLugin Variables
/****************************************************/

NSString* previousUpdatedLat = @"";
NSString* previousUpdatedLong = @"";

/**
 * Stores local Variables used by this plugin.
 */
CGFloat interval = 5.0;
int lastLocationUpdated = 0; // Value in seconds when last location updated.
int afterLastUpdateMinutes = 2;
int minimumDistanceChanged = 200; // In meters

/*****************************************/
#pragma mark - Life Cycle
/*****************************************/

- (void) startGettingBackgroundLocation: (CDVInvokedUrlCommand*)command;
{
    pluginCommand = command;

    if([command.arguments count] > 0) {
        if([command.arguments objectAtIndex:0] != nil) {
            interval = [[command.arguments objectAtIndex:0] doubleValue];
        }
        
        if([command.arguments objectAtIndex:1] != nil) {
            afterLastUpdateMinutes = [[command.arguments objectAtIndex:1] doubleValue];
        }
        
        if([command.arguments objectAtIndex:2] != nil) {
            minimumDistanceChanged = [[command.arguments objectAtIndex:1] doubleValue];
        }
    }
    
    // Converting into minutes for interval
    interval = interval * 60;

    // Converting into minutes for interval
    afterLastUpdateMinutes = afterLastUpdateMinutes * 60;
    
    [self initTimer: &interval];
    [self startTimerToGetLastLocationUpdateTime];
}


#pragma mark -
#pragma mark Our App Code.


/***********************************************************************/
#pragma mark - TImer For Catching Location
/***********************************************************************/

- (void)initTimer: (CGFloat*)interval   {

    if(![self canUpdateLocation]){
        [self.timer invalidate];
        return;
    };
    
     // Create the location manager if this object does not already have one.

    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];

    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startMonitoringSignificantLocationChanges];
    [self.locationManager setAllowsBackgroundLocationUpdates:YES];


    if (self.timer == nil) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:*interval
                                                      target:self
                                                        selector:@selector(checkUpdates:)
                                                        userInfo:nil
                                                        repeats:YES];
    }
}

- (void)checkUpdates: (NSTimer *)timer{
    
    if(![self canUpdateLocation]){
        [self.timer invalidate];
        return;
    };
    
//    UIApplication*    app = [UIApplication sharedApplication];
//    double remaining = app.backgroundTimeRemaining;
//    NSLog(@"This is application remainig time if background location not set for always%f", remaining);

    [self.locationManager startUpdatingLocation];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    NSString *latitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", coordinate.longitude];

    [self updateCallBack:pluginCommand latitude:latitude longitude:longitude];
}


-(void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    
	BOOL canUpdate = false;
    
    if(lastLocationUpdated < afterLastUpdateMinutes) {
        canUpdate = true;
    }
    
    if([previousUpdatedLat length] != 0 && [previousUpdatedLong length] != 0){
        CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:[previousUpdatedLat doubleValue] longitude:[previousUpdatedLong doubleValue]];
        CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:[newLocation coordinate].latitude longitude:[newLocation coordinate].longitude];
        CLLocationDistance distance = [startLocation distanceFromLocation:endLocation]; // aka double
        
        if(distance >= minimumDistanceChanged) {
            canUpdate = true;
        }
    }
    
    if(canUpdate) {
        [self updateLocationWithLatitude:[newLocation coordinate].latitude andLongitude:[newLocation coordinate].longitude];
    }
    
    UIApplication* app = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier bgTask =
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self initTimer: &interval];
    });
}

/****************************************************/
#pragma mark - Update Location.
/****************************************************/

-(void)updateLocationWithLatitude:(CLLocationDegrees)latitude
                     andLongitude:(CLLocationDegrees)longitude{
    
    NSString *lati = [NSString stringWithFormat:@"%f", latitude];
    NSString *longi = [NSString stringWithFormat:@"%f", longitude];
        
    /**
     * Preventing updating when lat & long comes like - 0.0000
     * Because this is returned by location manager when location not detected.
     */
    if([lati doubleValue] == 0.00 && [longi doubleValue] == 0.00) return;
    
    [self updateCallBack:pluginCommand latitude:lati longitude:longi];
    
}

- (void) updateCallBack:(CDVInvokedUrlCommand*)command latitude:(NSString*)latitude longitude:(NSString*)longitude  {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject: [NSString stringWithFormat:@"%@", latitude] forKey: @"lat"];
    [dict setObject: [NSString stringWithFormat:@"%@", longitude] forKey:  @"long"];
    
    // Store Lat Long to compare next time when user changes location.
    previousUpdatedLat = latitude;
    previousUpdatedLong = longitude;
        
    // Resetting Counter of last location Updated time (IN SECONDS)
    lastLocationUpdated = 0;
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


/************************************************/
#pragma mark - Timer Section
/************************************************/

-(void)startTimerToGetLastLocationUpdateTime
{
    self.lastLocationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(maitainLastLocationFiredTime) userInfo:nil repeats:YES];
}

- (void) maitainLastLocationFiredTime {
    lastLocationUpdated = lastLocationUpdated+1;
}

/********************************************************************************/
#pragma mark - Check Authorization For plugin.
/********************************************************************************/

- (BOOL) canUpdateLocation {

    if (![self isLocationServicesEnabled]) {
        [self returnLocationError:PERMISSIONDENIED withMessage:@"Location services are not enabled."];
        return false;
    }
    
    if (![self isAuthorized]) {
        NSString* message = nil;
        BOOL authStatusAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
        if (authStatusAvailable) {
            NSUInteger code = [CLLocationManager authorizationStatus];
            if (code == kCLAuthorizationStatusNotDetermined) {
                // could return POSITION_UNAVAILABLE but need to coordinate with other platforms
                message = @"User undecided on application's use of location services.";
            } else if (code == kCLAuthorizationStatusRestricted) {
                message = @"Application's use of location services is restricted.";
            }
        }
        
        // PERMISSIONDENIED is only PositionError that makes sense when authorization denied
        [self returnLocationError:PERMISSIONDENIED withMessage:message];

        return false;
    }
    
    return true;
}


/*********************************************************/
#pragma mark - Authorization Block
/**********************************************************/

- (BOOL)isAuthorized
{
    BOOL authorizationStatusClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+

    if (authorizationStatusClassPropertyAvailable) {
        NSUInteger authStatus = [CLLocationManager authorizationStatus];
        #ifdef __IPHONE_8_0
                if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {  //iOS 8.0+
                    return (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) || (authStatus == kCLAuthorizationStatusAuthorizedAlways) || (authStatus == kCLAuthorizationStatusNotDetermined);
                }
        #endif
        return (authStatus == kCLAuthorizationStatusAuthorizedAlways) || (authStatus == kCLAuthorizationStatusNotDetermined) || (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse);
    }

    // by default, assume YES (for iOS < 4.2)
    return YES;
}

- (BOOL)isLocationServicesEnabled
{
    BOOL locationServicesEnabledClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 4.x

    if (locationServicesEnabledClassPropertyAvailable) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    } else {
        return NO;
    }
}

/*********************************************/
#pragma mark - Send results
/*********************************************/

- (void) sendPluginResult: (CDVPluginResult*)result :(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)returnLocationError:(NSUInteger)errorCode withMessage:(NSString*)message
{
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];

    [posError setObject:[NSNumber numberWithUnsignedInteger:errorCode] forKey:@"code"];
    [posError setObject:message ? message:@"" forKey:@"message"];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];

    [self.commandDelegate sendPluginResult:result callbackId:pluginCommand.callbackId];
}

@end
