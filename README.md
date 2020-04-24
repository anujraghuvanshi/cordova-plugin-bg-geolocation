Plugin for the [cordova] framework to perform infinite background execution for geolocation.

#### Store Compliance

Infinite background tasks are not officially supported on most mobile operation systems and thus not compliant with public store vendors. A successful submssion isn't garanteed.

Use the plugin at your own risk!


## Supported Platforms

- __iOS__


## Installation
The plugin can be installed via [Cordova-CLI][CLI] and is publicly available on [NPM][npm].
	
`$ cordova plugin add https://github.com/Anuj-Raghuvanshi/cordova-plugin-bg-geolocation.git`

OR

`$ cordova plugin add cordova-plugin-bg-geolocation`

## Plugin options & usage

#### There are 3 options currently available with plugin: 
	'interval' => After how many minutes you want location update(In Minutes).
	'after_last_update_minutes' => If user changes location in b/w given interval, Then what should be time after which you need location update(In Minites).
	'minimum_distance_changed' => If user changes location in b/w given interval, What should be minimum distance covered in that period(In Meters).

#### Usage:

```
var options = {
	'interval': 5,
	'after_last_update_minutes': 2,
	'minimum_distance_changed': 200
}

cordova.plugins.backgroundMode.startGettingBackgroundLocation(options, function(location){
	// location
}, function(err) {
	// err
});
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request.