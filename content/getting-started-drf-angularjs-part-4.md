Title: Getting Started with Django REST Framework (DRF) and AngularJS (Part 4)
Date: 2016-09-22
Category: Development
Tags: django, django rest framework, angularjs
Slug: getting-started-drf-angularjs-part-4
Author: Tim Butler
Avatar: tim-butler

This is the fourth installment in a multi-part series geared toward getting started with Django Rest Framework (DRF) and AngularJS.  The goal of this series is to create an extensive, RESTful web application that uses DRF as a backend DB/API service and AngularJS as a frontend service connecting to the API.

__Read Previous Posts:__ 

- [Part 1 - Initial Project Setup](/blog/getting-started-drf-angularjs-part-1/)
- [Part 2 - Django Models and the ORM](/blog/getting-started-drf-angularjs-part-2/)
- [Part 3 - Serializers, views, and API routes](/blog/getting-started-drf-angularjs-part-3/)

__Write:__

- [Part 4 Supplementary Code](https://github.com/TrackMaven/getting-started-with-drf-angular/tree/part-4)

----

This post focuses on getting started with AngularJS, with topics covering

* [A Recap and an Introduction to AngularJS](#introduction)
* [Client Project Setup](#setup)
* [The Node Server](#nodeserver)
* [Angular Application Setup](#angularsetup)
* [The First Page](#results)

This guide uses [AngularJS](https://github.com/angular/angular.js) `1.5.7` and [Angular UI Router](https://github.com/angular-ui/ui-router) `0.3.1`.  Further, this guide assumes you have [Node.js](https://nodejs.org/en/) and [npm](https://www.npmjs.com/) installed on your system.

<a name="introduction"></a>
## A Recap and an Introduction to AngularJS
Last we met, we finished our API for the Retail module of our backend application.  The Retail module stores information about store chains, individual store locations, and employees working within each store.  The API allowed unfiltered access to each of these resources in a RESTful manner.

Our project goal is to create a client application that is deployed separately from the server application.  Now that we have an API defined and working, we can start working on the client that will connect to the API!

AngularJS if a front-end framework that provides two-way data binding between HTML and Javascript to dynamically display data.  It allows us to clearly define specific components of our application and tie the functions of the application JS to the HTML in a modular way.  

Our Angular frontend application will run a Node server to serve HTML templates to the user.  The Node server is very simple and send the user to the site index.  Angular will take care of the rest of the URL routing to act as a single page application.

<a name="setup"></a>
## Client Project Setup
First thing's first - we need to create a directory structure within the `drf-sample` directory for our client code.  

```
drf_sample/
├── client/
│   ├── bower.json
│   ├── index.html
│   ├── package.json
│   ├── public/
│   │   ├── app.js
│   │   ├── appRoutes.js
│   │   └── components/
│   └── server.js
└── server/
```

This structure contains a lot of files, so it is worthwhile to go over the main function of each as we setup our client project.

- `package.json` - Specifies project dependencies
- `bower.json` - Contains AngularJS package dependencies
- `index.html` - Acts as the entry point for our Angular application
- `server.js` - Serves the Angular application to the user
- `public/app.js` - Defines all modules associated with the Angular application
- `public/appRoutes.js` - Defines how a user can reach each application module
- `public/components/` - Will hold the source code for the application modules

To setup the project, we need to define and install our project depdencies.  First, we need to configure `package.json` to dowload `express` for our Node server and `bower` so we can install our Angular dependencies.  Add the following to `package.json`

```json
{
  "dependencies": {
    "express": "^4.13.4",
    "bower": "1.7.9"
  }
}
```
*Note: there are a number of fields in `package.json` left out of this example.  The [package.json documentation](https://docs.npmjs.com/files/package.json) does a great job at explaining what can be defined here.  For the purpose of this guide, the important takeaway is the dependencies section stating that we want to download `express` and `bower`.* 

Since we already have `npm` installed, we can install all of our project dependencies.

```shell
client$ cd client/
drf-sample/client$ npm install
```

The `node_modules` directory will be created within the client project  containing the contents of the packages installed.  

Now that we have bower downloaded, we can use [bower](https://bower.io/) to install the angular dependencies.  First, define the dependencies we want to install in `bower.json`.

```json
{
  "dependencies": {
    "angular": "^1.5.7",
    "angular-ui-router": "^0.3.1"
  }
}
```
*Note: there are a number of fields in `bower.json` left out of this example.  The [bower.json documentation](https://github.com/bower/spec/blob/master/json.md) does a great job at explaining what can be defined here.  For the purpose of this guide, the important takeaway is the dependencies section stating that we want to download `angular` and `angular-ui-router`.*

```shell
drf-sample/client$ bower install --config.interactive=false --allow-root
```

The `bower_components` directory will be created within the client project  containing the contents of the angular components installed.  

It's that easy!  We're ready to start coding our frontend server!

<a name="nodeserver"></a>
## The Node Server
The Node server is a very simple application that serves our Angular application to users.  We will be using [`express`](https://expressjs.com/), a minimalist web framework, to specify a directory and port for which to serve our application.

Edit the `server.js` file to include the following:

```
var express = require('express');
var server = express();
server.use(express.static(__dirname));

var port = process.env.PORT || 8081;
server.listen(port);
console.log('Use port ' + port + ' to connect to this server');

exports = module.exports = server;
```

The above code creates a new `express` instance, defines the directory to look for the entry point (in our case it's `index.html` in the current directory), define a port to run the server on, and export the instance so that we can access it from outside the file itself.  This allows us to run the server using node:

```
drf-sample/client$ node server.js 
Use port 8081 to connect to this server
```

Unfortunately, there isn't anything to serve, yet.  Let's change that!

<a name="angularsetup"></a>
## Angular Application Setup
This is where this post gets a little bit more complex.  The structure of AngularJS applications isn't necessarily difficult, but there are quite a few individual parts that come together to make the whole.  

AngularJS applications are made up of modules.  These modules are encapsulated pieces of code that perform specific functions within the application.  We will be building a component for our Retail application.  Eventually this module will query for Retail information from the Retail API and disply information about the retailers for the user.  

The first thing we need to do is define the Angular Retail module.  Add the following retail module files to the components directory:

```
components/
└── retail/
    ├── controllers/
    │   └── retail.control.js
    ├── services/
    └── templates/
        └── retail.template
```

The Retail module is split into three main parts: controllers, services, and templates.  Templates contain the HTML code that will be shown to the user.  Controllers are JS files that help to define what the templates display by modifying bound `$scope` varaibles that the templates reference.  Services are JS files that allow us to define classes and contact external APIs to bring data into the controllers.  

### Controllers

Let's modify the controller file

```javascript
angular
    .module('retail', [])
    .controller('RetailController', ['$scope', function($scope) {
        $scope.message = "Hello World";
}]);
```

and the template file

```html
<div ng-controller="RetailController">
    <div>
        {{ message }}
    </div>
</div>
```

These are very simple files to start with!  Let's talk about what's going on here.  The controller is defined as part of the "retail" module and given the name "RetailController".  We're injecting `$scope` into the controller which gives us access to use.  `$scope` is a links that connects templates controllers.  Anything defined on `$scope` in the controller can be used by the template and vice versa.  Here, we are defining `$scope.message` so any template that makes use of "RetailController" can use the message variable.

That being said, the template above defines a `div` with the `ng-controller` directive with a value of "RetailController".  You can read more about directives [here](https://docs.angularjs.org/guide/directive).  This gives the template use of the controller we defined.  Now, we can use the `$scope.message` variable by placing `message` in `{{ }}` tags to display text instead of providing a static string.  Whenever the `$scope.message` variable changes in the controller it will render on the template automatically.  Thanks two-way binding!

*Note: Notice we don't have to specify `$scope` when using variables in the template.  Any variables used in a template will automatically be assumed to be on `$scope`.  

Great!  We have our basic Retail module defined, but we need a way for the user to access it.  


### Application Routing
This is where `appRoutes.js` comes into play.  The sole purpose of `appRoutes.js` is to define states of the Angular application based on the URL the user visits.  Alter `appRoutes.js` with the following:

```javascript
angular
    .module('appRoutes', ["ui.router"])
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {
    $stateProvider.state({
        name: 'retail',
        url: '/',
        templateUrl: 'public/components/retail/templates/retail.template',
        controller: 'RetailController'
    });

    $urlRouterProvider.otherwise('/');
}]);
```

We have defined another module: "appRoutes" .  This module has a dependency on `ui.router` so that we can use `$stateProvider` to define application states.

One state has been defined.  When a user visits the base URL for our application, `/`, we want the user to see the retail module at the given template with the given controller.  "appRoutes" also specifies that when a user visits a URL that it has not explicitly defined then the user should be redirected back to `/`.  Great, the "Retail" module is now our default module!

### Full Application Definition

So far we have created two modules for the Angular application, but nothing is making use of those modules.  We need to define one more module that brings everything together.  Alter `app.js` with the following:

```javascript
'use strict';

angular
    .module('SampleApplication', [
        'appRoutes',
        'retail'
    ]);
```

"SampleApplication" is the main module that brings together all the modules we have created so far.  We inject `appRoutes` and `retail` into the app and leave it alone.  That's all we need to do.  There's one more step to get our application working!


<a name="results"></a>
## The First Page
Remember `index.html`? Well that file in the entry point to the Angular application.  Add the following code to `index.html`.

```html
<!DOCTYPE html>
<html ng-app="SampleApplication">
    <head>
        <meta charset="utf-8">
        <title>Angular Sample - Retail Application</title>

        <!--  Angular Setup -->
        <script src="bower_components/angular/angular.js"></script>
        <script src="bower_components/angular-ui-router/release/angular-ui-router.js"></script>

        <!-- Application Setup -->
        <script src="public/appRoutes.js"></script>
        <script src="public/app.js"></script>

        <!--  Controllers -->
        <script src="public/components/retail/controllers/retail.control.js"></script>
    </head>
    <body>
        <!-- The dynamic templates will be served within this div -->
        <ui-view></ui-view>
    </body>
</html>
```

At heart `index.html` is just the beginning to a standard page, but there are a few key differences.  First, the `np-app` directive is being used to specify that we want to use `SampleApplication` as the angular application for this page.  Next, there are multiple `script` elements to import everything we need for the application.  It's important to import all non-template parts of the application here, including the `angular.js` and `angular-ui-router.js` packages from bower.  

Lastly, the `ui-view` directive is being used to dynamically place our templates into the page.  When the user changes URLs within our page the `appRoutes` module determines which module is being used for the URL and displays it in place of `ui-view`.  This, in essence, is how the single page application works.  Views are dynamically determined by the Angular router.

That's it!  If we run the `node server.js` then we can visit the page we have created!

<center>![map3](/images/sample-app-hello.png)</center>

## Looking Forward

We now have a fully functional AngularJS application.  It's simple, yes, but lays the foundation for the rest of the application.  Next time we can start utilizing the Retail API and displaying the results for the user! 
