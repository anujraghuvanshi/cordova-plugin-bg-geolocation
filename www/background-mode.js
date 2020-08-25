
var exec    = require('cordova/exec'),
    channel = require('cordova/channel');

	/**
	 * Activates the background mode. When activated the application
	 * will be prevented from going to sleep while in background
	 * for the next time.
	 *
	 * @return [ Void ]
	 */
	exports.startGettingBackgroundLocation = function(params, successCallback, errCallback)
	{
		var fn = function() {
			exports._isEnabled = true;
			exports.fireEvent('enable');
		};

		var interval = params.interval;
		var afterLastUpdateMinutes = params.after_last_update_minutes;
		var minimumDistanceChanged = params.minimum_distance_changed;
		var timeSlot = params.time_slot;


		cordova.exec(successCallback, errCallback, 'BackgroundMode', 'startGettingBackgroundLocation', [interval, afterLastUpdateMinutes, minimumDistanceChanged, timeSlot]);
	};

	exports.switchToLocationSettings = function()
	{
		cordova.exec(null, null, 'BackgroundMode', 'switchToLocationSettings');
	};

	exports.switchToSettings = function()
	{
		cordova.exec(null, null, 'BackgroundMode', 'switchToSettings');
	};

	exports.disable = function()
	{
		cordova.exec(null, null, 'BackgroundMode', 'disable');
	};

	// Called before 'deviceready' listener will be called
	channel.onCordovaReady.subscribe(function()
	{
		channel.onCordovaInfoReady.subscribe(function() {
			// 
		});
	});

	// Called after 'deviceready' event
	channel.deviceready.subscribe(function()
	{
		// Perform Actions on device ready
	});
