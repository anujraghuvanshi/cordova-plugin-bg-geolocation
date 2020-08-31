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
CGFloat interval = 10.0;
int lastLocationUpdated = 0; // Value in seconds when last location updated.
int afterLastUpdateMinutes = 2;
int minimumDistanceChanged = 200; // In meters
NSDictionary *timeSlot;


/*****************************************/
#pragma mark - Life Cycle
/*****************************************/

- (void) startGettingBackgroundLocation: (CDVInvokedUrlCommand*)command
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
            minimumDistanceChanged = [[command.arguments objectAtIndex:2] doubleValue];
        }
        
        if([command.arguments objectAtIndex:3] != nil) {
            timeSlot = [command.arguments objectAtIndex:3];
        }
    }
 
    // Converting into seconds for interval
    interval = interval * 60;

    // Converting into seconds for interval
    afterLastUpdateMinutes = afterLastUpdateMinutes * 60;
    
    if([self canUpdateLocationNow]) {
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)); // 1
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){ // 2
            [self updateCurrentLocationData];
        });
        [self initTimer: &interval];
        [self startTimerToGetLastLocationUpdateTime];
    }
}

- (BOOL) canUpdateLocationNow{
    
    NSString* startTimeFromSetting = [timeSlot objectForKey:@"start_time"];
    NSString* endTimeFromSetting = [timeSlot objectForKey:@"end_time"];
    NSArray* allowedDays = [timeSlot objectForKey:@"days"];
    NSDate *CurrentDate = [NSDate date];
    NSMutableArray * weekDaysStrings = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSArray *daySymbols = dateFormatter.standaloneWeekdaySymbols;

    for(int i = 0; i < allowedDays.count; i++) {
        NSInteger dayIndex = [allowedDays[i] doubleValue];
        NSString *dayName = daySymbols[dayIndex % 7];
        [weekDaysStrings addObject:dayName];
    }
    
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *dayName = [dateFormatter stringFromDate:CurrentDate];
    
    BOOL isAllowedForDay = [weekDaysStrings containsObject:dayName];

    if(isAllowedForDay) {
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        NSString *nowTimeString = [dateFormatter stringFromDate:[NSDate date]];
        
        int startTime = [self minutesSinceMidnight:[dateFormatter dateFromString:[startTimeFromSetting stringByAppendingString:@":00"]]];
        int endTime   = [self minutesSinceMidnight:[dateFormatter dateFromString:[endTimeFromSetting stringByAppendingString:@":00"]]];
        int nowTime   = [self minutesSinceMidnight:[dateFormatter dateFromString:nowTimeString]];
        
        if (startTime <= nowTime && nowTime <= endTime){
            return true;
        }
        
        return false;
    }
    
    return false;
    
}

-(int) minutesSinceMidnight:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond  fromDate:date];
    return 60 * (int)[components hour] + (int)[components minute];
}

- (void) switchToLocationSettings: (CDVInvokedUrlCommand*)command
{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void) switchToSettings: (CDVInvokedUrlCommand*)command
{
    // 
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
    
    [self updateCurrentLocationData];
}


- (void) updateCurrentLocationData {
        
    if(![self canUpdateLocationNow]) return;
    
//    UIApplication*    app = [UIApplication sharedApplication];
//    double remaining = app.backgroundTimeRemaining;
//    NSLog(@"This is application remainig time if background location not set for always%f", remaining);

    [self.locationManager startUpdatingLocation];
    [self.locationManager stopUpdatingLocation];
    //    [self.locationManager startMonitoringSignificantLocationChanges ];
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    
    NSString *latitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", coordinate.longitude];
    
    
    [self updateCallBack:pluginCommand latitude:latitude longitude:longitude];
}


//-(void)locationManager:(CLLocationManager *)manager
//    didUpdateToLocation:(CLLocation *)newLocation
//           fromLocation:(CLLocation *)oldLocation{
//
//    BOOL canUpdate = false;
//
//    if(lastLocationUpdated < afterLastUpdateMinutes) {
//        canUpdate = true;
//    }
//
//    if([previousUpdatedLat length] != 0 && [previousUpdatedLong length] != 0){
//        CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:[previousUpdatedLat doubleValue] longitude:[previousUpdatedLong doubleValue]];
//        CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:[newLocation coordinate].latitude longitude:[newLocation coordinate].longitude];
//        CLLocationDistance distance = [startLocation distanceFromLocation:endLocation]; // aka double
//
//        if(distance >= minimumDistanceChanged) {
//            canUpdate = true;
//        }
//    }
//
////    if(canUpdate) {
////        [self updateLocationWithLatitude:[newLocation coordinate].latitude andLongitude:[newLocation coordinate].longitude];
////    }
//
//    UIApplication* app = [UIApplication sharedApplication];
//
//    __block UIBackgroundTaskIdentifier bgTask =
//    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
//        [app endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    }];
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self initTimer: &interval];
//    });
//}

/****************************************************/
#pragma mark - Update Location.
/****************************************************/
//
//-(void)updateLocationWithLatitude:(CLLocationDegrees)latitude
//                     andLongitude:(CLLocationDegrees)longitude{
//
//    NSString *lati = [NSString stringWithFormat:@"%f", latitude];
//    NSString *longi = [NSString stringWithFormat:@"%f", longitude];
//
//    /**
//     * Preventing updating when lat & long comes like - 0.0000
//     * Because this is returned by location manager when location not detected.
//     */
//    if([lati doubleValue] == 0.00 && [longi doubleValue] == 0.00) return;
//
//    [self updateCallBack:pluginCommand latitude:lati longitude:longi];
//
//}

- (void) updateCallBack:(CDVInvokedUrlCommand*)command latitude:(NSString*)latitude longitude:(NSString*)longitude  {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject: [NSString stringWithFormat:@"%@", latitude] forKey: @"lat"];
    [dict setObject: [NSString stringWithFormat:@"%@", longitude] forKey:  @"long"];
    
//    if(previousUpdatedLat == latitude && previousUpdatedLong == longitude) return;
    
    if([previousUpdatedLat length] != 0 && [previousUpdatedLong length] != 0){
        CLLocation *startLocation = [[CLLocation alloc] initWithLatitude:[previousUpdatedLat doubleValue] longitude:[previousUpdatedLong doubleValue]];
        CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
        CLLocationDistance distance = [startLocation distanceFromLocation:endLocation]; // aka double
        
//        if(distance <= minimumDistanceChanged) {
//            return;
//        }
    }
    
    
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

// Checks if location can be updated based on location permission settings.
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


/*************************************************/
#pragma mark - Disable Plugin
/*************************************************/

- (void) disable:(CDVInvokedUrlCommand *)command
{
    [self.timer invalidate];
    [self.locationManager stopUpdatingLocation];
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
