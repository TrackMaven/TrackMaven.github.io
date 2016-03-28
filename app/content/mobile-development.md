Title: Monthly Challenge: Mobile Development
Date: 2015-02-17
Category: Monthly Challenge
Tags: mobile, ionic, 
Slug: monthly-challenge-mobile-development
Author: Fletcher Heisler
Avatar: fletcher-heisler

TrackMaven's next [Monthly Challenge](www.meetup.com/TrackMaven-Monthly-Challenge/) meetup will cover [mobile development](http://www.meetup.com/TrackMaven-Monthly-Challenge/events/219945053/). To help kickstart some projects, in this post I'll cover the basics of one way to get started creating a cross-platform mobile app.

We'll be using [Ionic](http://ionicframework.com/), a framework for making beautiful, responsive mobile apps using HTML5 and AngularJS. Ionic sits on top of [Cordova](http://cordova.apache.org/) and has a [complicated relationship](http://ionicframework.com/blog/what-is-cordova-phonegap/) with [PhoneGap](http://phonegap.com/), both of which can also be used individually for writing cross-platform mobile applications. A few other possible options for getting started in mobile development:

- [React Native](http://jlongster.com/First-Impressions-using-React-Native) is (as of this post) not yet publicly released but shows tremendous promise
- Go native with the [Android SDK](http://developer.android.com/sdk/index.html) and start [jumping through hoops](https://developer.apple.com/library/ios/referencelibrary/GettingStarted/RoadMapiOS/index.html) to develop on Apple's iOS
- Try out [Kivy](http://kivy.org/) for writing mobile (and non-mobile) apps in Python! I personally haven't had great luck getting Kivy apps to compile on multiple devices, but it's definitely an appealing concept
- Appcelerator's [Titanium](http://www.appcelerator.com/titanium/) uses a JavaScript-based SDK and covers iOS, Android, Windows, BlackBerry and HTML5; I haven't tried it out, but have heard that in some cases (especially on older devices) it may be more performant than Ionic, being a step or two closer to native code

For this Ionic example, we're going to cover the following:
- Push a sample app to iOS and Android emulators + devices (without forking over $99 to Apple)
- Set up custom styles using Sass
- Convert the sample JS to CoffeeScript with automatic gulp compilation
- Add custom icons and a splash screen

Let's get to it!

## Dependencies

First off, you'll need to have [Node.js](http://nodejs.org/) installed, then install the `ionic` NPM package:

```sudo npm install -g cordova ionic```

You can now create a new Ionic project using one of three templates:

- `blank` - you guessed it
- `tabs` - includes a title header bar and "home", "star", and "settings" buttons on a footer
- `sidemenu` - includes a collapsible lefthand sidebar

ionic start myprojectname sidemenu
cd myprojectname/
ionic serve

After changing into the `myprojectname` directory (or whatever you want to name it), running `ionic serve` will start up the sample project on localhost and automatically open the running app in your browser. Ship it!

> One important note: when testing your app locally, because of [CORS](http://enable-cors.org/) rules, you won't be able to access any external data. For instance, calling an API or even loading in a picture from the web will be blocked by default on most browsers.

There are a few ways around this; for instance, you *could* use JSONP instead of `$http` calls, mess with request headers, load up a separate brower without CORS protection... **or** my preferred method: just use a [Chrome plugin](https://chrome.google.com/webstore/detail/cors-toggle/omcncfnpmcabckcddookmnajignpffnh?hl=en) to toggle CORS on and off. This isn't the most secure, idea, so make sure you're only purposefully allowing cross domain requests while testing your app, not browsing the web.


## Run it on iOS

Before diving into the code, let's make sure we can get the app on all our devices. For loading the project onto an iOS device, the first steps is to [have XCode](https://developer.apple.com/xcode/downloads/). Next you'll need to add iOS as a platform for the Ionic project and build the project for iOS:

```
ionic platform add ios
ionic build ios
```

This will create a `.xcodeproj` file in `/platform/ios`. Optionally, you can install and run the iOS simulator to run the app within an on-screen iDevice of choice:

```
npm install -g ios-sim
ionic emulate ios
```

To get the project running on a physical iDevice, previously you would have had to sign up for a $99 developer license, then build/load the project onto the device from within XCode. However, Ionic has recently released a wonderful workaround in their [Ionic View for iOS](http://ionicframework.com/blog/view-app-is-alive/).

With the Ionic View app, you can first sign up for an account with Ionic [here](https://apps.ionic.io/signup), then [download the free app](https://itunes.apple.com/us/app/ionic-view/id849930087) from the iTunes store onto your device of choice. Finally, just run:

```ionic upload```

You'll need to authenticate your Ionic account, then the project will be uploaded [here](http://apps.ionic.io/projects) and available for viewing/testing from within Ionic View on the iOS device!


## Run it on Android

First, let's get dependencies set up. We'll need:

- [ant](http://ant.apache.org/bindownload.cgi); run `ant -version` to check if you have it already
- the [Android SDK](http://developer.android.com/sdk/index.html); if you're using brew, run `brew install android-sdk`
- all default selected packages from Android's package manager. Run `android` to enter the manager; you may need to run this command multiple times to re-enter the package manager and get all the defaults installed.

Now we can add `android` as a platform to the Ionic project:

```ionic platform add android```

If you get the error: 
```Error: ANDROID_HOME is not set and "android" command not in your PATH.```

You'll need to add the path to `android` to your `PATH`. To find the right location, run `android` and note the root folder of the SDK, then find the full path to the specific tool; for me, having installed through `brew`, the path to add was `/usr/local/Cellar/android-sdk/r21.1/tools`

Now we can build the project for Android:

```ionic build android```

Optionally, if you want to use an Android emulator to test on various devices, we can set up an "AVD" - an Android Virtual Device. Full details are available [here](http://developer.android.com/tools/devices/managing-avds-cmdline.html), but the short version is:

- Run `android list targets` to get a list of possible images along with IDs
- Choose an image and run `android create avd -n {name} -t {ID}`, where {name} is for instance "myandroid" and {ID} is the target ID number.
- Some platforms have multiple ABIs (like choosing an API, but at the machine code level), in which case you'll need to specify one using the `-b` flag

As an example, I used:
```android create avd -n andefault1 -t 2 -b default/armeabi-v7a```

Finally, spin up the emulator:

```ionic emulate android```

To get the app running on a physical Android device, plug the device into USB and run:

```ionic run android```

If nothing happens, you might need to swipe the device's top menu down and select an option like "charge only" mode. You can use the Android debugger to list all available devices and check if the phone is being recognized:

```adb devices -l```


## Roll your own Sass

We've still got a default template! We can customize the styling of the app using [Sass](http://sass-lang.com/guide). To get set up, first run this intuitive command:

```ionic setup sass```

All of our Sass will be loaded in the file `./scss/ionic.app.scss` - this will point to `www/lib/ionic/scss` for *many* separate SCSS files that can all be customized in style. Take a look at the color definitions at the top of `www/lib/ionic/scss/_variables.scss`:

```sass
$light:                           #fff !default;
$stable:                          #f8f8f8 !default;
$positive:                        #4a87ee !default;
$calm:                            #43cee6 !default;
$balanced:                        #66cc33 !default;
$energized:                       #f0b840 !default;
$assertive:                       #ef4e3a !default;
$royal:                           #8a6de9 !default;
$dark:                            #444 !default;
```

For a quick and highly visible win, we can change around the hex codes in this file to modify the app's main color palette.

Running `ionic serve` will use [gulp](http://gulpjs.com/) to check for and automatically recompile any Sass changes.


## Set up CoffeeScript

At TrackMaven, we write a lot of [CoffeeScript](http://coffeescript.org/) instead of raw JavaScript; this tends to save a lot of time/eyesore/etc if you know what you're doing, especially coming from a Python background. So, let's set up this Ionic project to compile `coffee` files into JS!

First, some minor updates to the main page, `index.html`:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1, maximum-scale=1, user-scalable=no, width=device-width">
    <title></title>

    <link href="css/ionic.app.css" rel="stylesheet">
    <script src="lib/ionic/js/ionic.bundle.js"></script>
    <script src="cordova.js"></script>
    <script src="js/app.js"></script>
  </head>

  <body ng-app="app">
    <ion-nav-view></ion-nav-view>
  </body>
</html>
```

Here we just renamed `ng-app` from "starter" and point to a (future) compiled `app.js` file rather than individual JS files.

Now, move the current `app.js` and `controllers.js` files to a new folder `/www/coffee` and rename then to have `.coffee` extensions. We could leave them as-is, since JavaScript is valid CoffeeScript, but let's convert them to actual CoffeeScript so that we can more easily make modifications later.

`app.coffee` ends up looking something like:

```coffeescript
angular.module('app', ['ionic', 'app.controllers'])

.run(($ionicPlatform) ->
  $ionicPlatform.ready ->
    # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    # for form inputs)
    if (window.cordova && window.cordova.plugins.Keyboard)
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true)

    if (window.StatusBar)
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault()
)

.config(($stateProvider, $urlRouterProvider) ->
  $stateProvider.state('app', {
    url: "/app",
    abstract: true,
    templateUrl: "templates/menu.html",
    controller: 'AppCtrl'
  }
  ).state('app.search', {
    url: "/search",
    views: {
      'menuContent': {
        templateUrl: "templates/search.html"
      }
    }
  }
  ).state('app.browse', {
    url: "/browse",
    views: {
      'menuContent': {
        templateUrl: "templates/browse.html"
      }
    }
  }
  ).state('app.playlists', {
    url: "/playlists",
    views: {
      'menuContent': {
        templateUrl: "templates/playlists.html",
        controller: 'PlaylistsCtrl'
      }
    }
  }
  ).state('app.single', {
    url: "/playlists/:playlistId",
    views: {
      'menuContent': {
        templateUrl: "templates/playlist.html",
        controller: 'PlaylistCtrl'
      }
    }
  })

  # if none of the above states are matched, use this as the fallback
  $urlRouterProvider.otherwise('/app/playlists')
)
```

While our `controllers.coffee` file is as follows:

```coffeescript
angular.module('app.controllers', [])

.controller('AppCtrl', ($scope, $ionicModal, $timeout) ->
  # Form data for the login modal
  $scope.loginData = {}

  # Create the login modal that we will use later
  $ionicModal.fromTemplateUrl('templates/login.html', {
    scope: $scope
  }).then((modal) ->
    $scope.modal = modal
  )

  # Triggered in the login modal to close it
  $scope.closeLogin = ->
    $scope.modal.hide()

  # Open the login modal
  $scope.login = ->
    $scope.modal.show()

  # Perform the login action when the user submits the login form
  $scope.doLogin = ->
    console.log('Doing login', $scope.loginData)
    $scope.closeLogin()
)

.controller('PlaylistsCtrl', ($scope) ->
    $scope.playlists = [
      { title: 'Reggae', id: 1 },
      { title: 'Chill', id: 2 },
      { title: 'Dubstep', id: 3 }
    ]
)

.controller('PlaylistCtrl', ($scope, $stateParams) ->
)
```

Now we need to set up CoffeeScript auto-compilation to get our `.coffee` files loaded into `app.js` whenever a change is made. In `/gulpfile.js`, add the following:

At the top with the other global variable declarations:
```var coffee = require('gulp-coffee');```

Add a folder to the compilation paths:
```
var paths = {
  sass: ['./scss/**/*.scss'],
  coffee: ['./www/**/*.coffee']
};
```

Add `coffee` to the `watch` task:
```
gulp.task('watch', function() {
  gulp.watch(paths.sass, ['sass']);
  gulp.watch(paths.coffee, ['coffee']);
});
```

Then add the full `coffee` task:
```
gulp.task('coffee', function(done) {
  gulp.src(paths.coffee)
  .pipe(coffee({bare: true}).on('error', gutil.log))
  .pipe(concat('app.js'))
  .pipe(gulp.dest('./www/js'))
  .on('end', done)
})
```

Finally, you'll need to add `gulp-coffee`:
```npm install gulp-coffee --save```

Then make sure that `gulp-coffee` has been added to `package.json` as a dependency. Now run `ionic serve` and make changes to the `.coffee` files to automatically recompile `app.js` and reload the app!


## Add custom icons and splash screen

This step used to be a hassle to manage, but Ionic has [recently automated](http://ionicframework.com/blog/automating-icons-and-splash-screens/) nearly the entire process:

- Add a root `resources` directory to the project
- In `resources`, add a 192x192px or larger `icon.png` file (or `.psd`, `.ai`)
- In `resources`, add a 2208x2208px or larger `splash.png` file (or `.psd`, `.ai`)
- Run `ionic resources` to automatically generate all the appropriate files
- Add the `--icon` or `--splash` options to update only one set of resource

This [post](http://ionicframework.com/blog/automating-icons-and-splash-screens/) from Ionic has more details around the particular design aspects, but that's about it!

### Some possible next steps...

- Set up an actual login page with authentication with [JSON Web Tokens](http://jamesbrewer.io/2014/09/22/json-web-token-authentication-part-one/)
- Use Angular [$http](https://docs.angularjs.org/api/ng/service/$http) requests to load in some external data
- Add in [infinite scroll](http://ionicframework.com/docs/api/directive/ionInfiniteScroll/) to query endless paginated data (what else are smartphones for?)
- [Publish your app](http://ionicframework.com/docs/guide/publishing.html) 
- ????
- Profit!
