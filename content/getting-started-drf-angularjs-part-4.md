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
Last we met, we finished the API for the Retail module of our Django backend application.  The Retail module contains information about store chains, individual store locations, and employees working within each store.  The API provides access to each of these resources in a RESTful manner.

Our project goal is to create a frontend application that can be deployed separately from the backend application.  Now that we have an API defined and working, we can start working on the AngularJS client that will utilize the API!  AngularJS is a front-end framework that provides two-way data binding between HTML and Javascript to dynamically display data.  It allows us to clearly define application components and tie the components to the HTML templates.

Our Angular application will run on a Node server.  The Node server will be a very simple application that serves the Angular application to the user and that is all.  Angular will take care of the URL routing so that it may act as a [single page application](https://en.wikipedia.org/wiki/Single-page_application).

<a name="setup"></a>
## Client Project Setup
First thing's first - we need to setup our client application that will house both the code for the Node server and the code for the Angular application.  To start, create the following directory structure within  `drf-sample`.

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
└── └── server.js
```

This structure contains a a lot, so it is worthwhile to go over the main function of each part as we setup our client project.

- `package.json` - Specifies overall project dependencies
- `bower.json` - Specifies AngularJS dependencies
- `index.html` - Acts as the entry point for our Angular application
- `server.js` - Serves the Angular application to the user
- `public/app.js` - Defines all modules associated with the Angular application
- `public/appRoutes.js` - Defines how a user can reach each application module
- `public/components/` - Hold the source code for application module

To setup the project, we need to define and install our project dependencies.  First, configure `package.json` to download `express` for our Node server and `bower` so we can install our Angular dependencies.

----

*package.json*
```json
{
  "dependencies": {
    "express": "^4.13.4",
    "bower": "1.7.9"
  }
}
```

*Note:* There are a number of fields possible in `package.json` left out of this example.  The [package.json documentation](https://docs.npmjs.com/files/package.json) does a great job at explaining what can be defined here.  For the purpose of this guide, the important takeaway is the dependencies section stating that we want to download `express` and `bower`.

----

Since we already have `npm` installed, we can install all of our project dependencies.

```shell
client$ cd client/
drf-sample/client$ npm install
```

`node_modules` is created within the client directory and contains the contents of both installed packages.  Now that we have [bower](https://bower.io/) downloaded, we can use it to install the angular dependencies.  First, define the angular dependencies in `bower.json`.

----

*bower.json*
```json
{
  "dependencies": {
    "angular": "^1.5.7",
    "angular-ui-router": "^0.3.1",
    "angular-bootstrap": "^1.3.3"
  }
}
```

*Note:* There are a number of fields possible in `bower.json` left out of this example.  The [bower.json documentation](https://github.com/bower/spec/blob/master/json.md) does a great job at explaining what can be defined here.  For the purpose of this guide, the important takeaway is the dependencies section stating that we want to download `angular`, `angular-ui-router`, and `angular-bootstrap`.

----

Next, install the dependencies using bower.

```shell
drf-sample/client$ bower install --config.interactive=false --allow-root
```

`bower_components` is created within the client directory and contains the contents of the installed angular components.

It's that easy!  We have downloaded all of our required dependencies, so now we can start coding our frontend server.

<a name="nodeserver"></a>
## The Node Server
The Node server is a very simple application that serves our Angular application to users.  We will be using [`express`](https://expressjs.com/), a minimalist web framework, to specify a directory and port for which to serve the application.  To start, edit the `server.js` file to contain the server code:

----

*server.js*
```
var express = require('express');
var server = express();
server.use(express.static(__dirname));

var port = process.env.PORT || 8081;
server.listen(port);
console.log('Use port ' + port + ' to connect to this server');

exports = module.exports = server;
```

----

This code creates a new `express` instance, defines the directory to look for as the entry point (in our case it's the current directory), defines a port to run the server on, and exports the `express` instance so that we can access it from outside the file.  With this setup we can run the server using the following:

```
drf-sample/client$ node server.js 
Use port 8081 to connect to this server
```

Unfortunately, if you visit `localhost:8081` you will see a blank page.  There isn't anything to serve until the Angular application is created.

<a name="angularsetup"></a>
## Angular Application Setup
This is where things get a bit more complex.  The structure of AngularJS applications isn't necessarily difficult, but there are a few individual parts that come together to make the whole.  

AngularJS applications are made up of modules.  These modules are encapsulated pieces of code that perform specific functions within the application.  We will be building a component for our Retail application.  Eventually, this module will query for Retail information from the Retail API and display information about retailers.  For the purpose of this post, however, we will just be printing the standard "Hello World" to the page to prove that the application has been created correctly.  

First, define the Angular Retail module.  Add the following retail module files to the components directory:

```shell
components/
└── retail/
    ├── controllers/
    │   └── retail.control.js
    ├── services/
    └── templates/
        └── retail.template
```

Angular modules can typically be split into three main parts: controllers, services, and templates.  Templates contain the HTML code shown to the user.  Controllers are JS files that define dynamic content displayed by the templates through `$scope` variables.  Services are helper JS files typically used to define classes, contact external APIs, etc.

### Full Application Definition

Since Angular applications are just a combination of modules, there are a few modules that we need to define.  First, the `retail` module will hold all controller, service, and template code that involves the Retail API.  Then we need to define the main application module that uses `retail`.

Alter `app.js` with the following:

----

*app.js*
```javascript
'use strict';

var retail = angular.module("retail", []);

angular
    .module('SampleApplication', [
        'appRoutes',
        'retail'
    ]);
```

----

Here we created an angular module named `retail`.  Nothing is defined as part of this module yet, but having the module available will come in handy later.  Second, the `SampleApplication` module is created.  This will act as the main module that brings together all other modules within the application.  `appRoutes` and `retail` are dependencies for `SampleApplication`.  Don't worry about `appRoutes` for now, we will get to that later.  Let's start on the `retail` module.

### Controllers and Templates

As a first pass, the `retail` module will have two parts: a controller and a template.  This is a good place to start since they are so directly connected.  Modify the `retail` controller and template files with the following:

----

*retail.control.js*
```javascript
retail
    .controller('RetailController', ['$scope', function($scope) {
        $scope.message = "Hello World";
}]);
```

*retail.template*
```html
<div ng-controller="RetailController">
    <div>
        {{ message }}
    </div>
</div>
```

----

So, what is going on here?  By using `retail.controller` we are stating that this controller is defined as part of the `retail` module from `app.js`.  The controller is given the name "RetailController".  `$scope` is injected into the controller so the controller has access to it.  Think of `$scope` as a link that connects templates to controllers.  Any vairables defined on `$scope` in the controller can be used by corresponding templates and vice versa.  The `$scope.message` variable is defined within the controller.  Any template using "RetailController" can view and alter the `message` variable.

The template defines a `div` with the `ng-controller` directive pointing to "RetailController".  You can read more about directives [here](https://docs.angularjs.org/guide/directive).  This provides the template use of "RetailController" and the `message` variable.  By placing `message` in `{{ }}` tags, the template displays text stored by the variable instead of a static string.  Whenever the `$scope.message` variable changes in the controller it will render on the template automatically thanks to variable binding!

----

*Note:* Notice we don't have to specify `$scope` when using variables in the template.  Any variables used in a template will automatically be assumed to be on `$scope`.  

----

Great!  We have our basic `retail` control module defined, but we still need a way for the user to access it.  


### Application Routing
This is where `appRoutes.js` comes into play.  `appRoutes.js` defines states of the Angular application based on the URL the user visits.  When the user visits a new URL, `appRoutes` determines the template and controller that should be used by that URL.  Alter `appRoutes.js` with the following:

----

*appRoutes.js*
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

----

Here, another module is defined: `appRoutes` .  This module has a dependency on `ui.router` so that we can use [`$stateProvider`](https://github.com/angular-ui/ui-router/wiki) to alter application states.

One state is defined in `appRoutes`: "retail".  When users visit the base URL for our application, `/`, we want them to see the Retail control module using the retail template and controller.  

Further, `appRoutes` states that users should be redirected to `/` when they visit a URL that has not explicitly defined.  

<a name="results"></a>
## The First Page
Remember `index.html`? Well that file in the entry point to the Angular application.  Add the following code to `index.html`.

----

*index.html*
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

----

At heart `index.html` is just the beginning to a standard page, but there are a few key differences.  First, the `ng-app` directive is used to specify that `SampleApplication` will be the angular application for this page.  Next, there are multiple `script` elements to importing everything we need for the application.  It's important to import all non-template parts of the application here, including the `angular.js` and `angular-ui-router.js` packages from bower.

Lastly, the `ui-view` directive is being used to dynamically place our application states into the page.  When the user changes URLs within our page `appRoutes` determines which module is should be rendered and displays it in place of `ui-view`.  This, in essence, is how the single page application works.  Views are dynamically determined by the Angular router.

That's it!  If we run `node server.js` then we can visit the page that we created!

<center>![map3](/images/sample-app-hello.png)</center>

## Looking Forward

We now have a fully functional AngularJS application.  It's simple, yes, but it lays the foundation for the rest of the application.  Next time we can start utilizing the Retail API and displaying the API results for the user! 
