Title: Getting Started with Django REST Framework (DRF) and AngularJS (Part 5)
Date: 2016-12-30
Category: Development
Tags: django, django rest framework, angularjs
Slug: getting-started-drf-angularjs-part-5
Author: Tim Butler
Avatar: tim-butler

This is the fourth installment in a multi-part series geared toward getting started with Django Rest Framework (DRF) and AngularJS.  The goal of this series is to create an extensive, RESTful web application that uses DRF as a backend DB/API service and AngularJS as a frontend service connecting to the API.

__Read Previous Posts:__ 

- [Part 1 - Initial Project Setup](/blog/getting-started-drf-angularjs-part-1/)
- [Part 2 - Django Models and the ORM](/blog/getting-started-drf-angularjs-part-2/)
- [Part 3 - Serializers, views, and API routes](/blog/getting-started-drf-angularjs-part-3/)
- [Part 4 - Client Project Setup](/blog/getting-started-drf-angularjs-part-4/)

__Write:__

- [Part 5 Supplementary Code](https://github.com/TrackMaven/getting-started-with-drf-angular/tree/part-5)

----

This post focuses on connecting our AngularJS application with the existing Django Retail application backend.

* [A Recap and Introduction to AngularJS Services](#introduction)
* [Angular Resource](#resource)
* [Retail Services](#services)
* [Making Use of the Retail Services](#using-services)
* [Displaying API Results in the Template](#template)
* [Running it All Together](#running)

This guide uses [AngularJS](https://github.com/angular/angular.js) `1.5.7` and [Angular UI Router](https://github.com/angular-ui/ui-router) `0.3.1`.  Further, this guide assumes you have [Node.js](https://nodejs.org/en/) and [npm](https://www.npmjs.com/) installed on your system.

<a name="introduction"></a>
## A Recap and Introduction to AngularJS Services
In the previous post, we got out Angular application up and running in a very minimal way.  A minimal as it was, the framework put into place allows us to build on top of it to begin integrating data from the backend *Retail* application previously created.  This post will over the basics on AngularJS services - injectable Angular modules that can be shared across your application to perform common functions.  

By the end of this post we will have defined a service that contacts the *Retail* API and displays the results of the query onto our main page.

<a name="resource"></a>
## Angular Resource (ngResource)

There are many ways to contact an API through Angular.  For example, we could use [`$http`](https://docs.angularjs.org/api/ng/service/$http), but its a bit raw and is used for general purpose requests.  We want to create a RESTful web application.   The [`Angular Resource`, or `ngResource`](https://docs.angularjs.org/api/ngResource) package wraps `$http` functionality for RESTful APIs.  For this guide we will be using `ngResource` to contact our APIs.

To use `ngResource` we need add it as a dependency for the AngularJS application.  Change the `bower.json` dependencies to contain `angular-resource` and add a resolutions section (this will eliminate potential Angular version conflicts).

```
...
  "dependencies": {
    "angular": "^1.5.7",
    "angular-ui-router": "^0.3.1",
    "angular-bootstrap": "^1.3.3",
    "angular-resource": "~1.4.8"
  },
  "resolutions": {
    "angular": "^1.5.7"
  }
...
```

Then run the bower install command in the client directory.

```shell
drf-sample$ cd server
drf-sample/client$ bower install --config.interactive=false --allow-root
```

If all goes well then `angular-resource` will be installed into the `bower_components` directory.  Great!  It's installed, but the application is still unable to use it.  Next, we need to import it for our application add `ngResource` as a dependency for our application module.  

Add `angular-resource.min.js` as a dependency in `index.html`.

*index.html*
```html
...
        <!--  Angular Setup -->
        <script src="bower_components/angular/angular.js"></script>
        <script src="bower_components/angular-ui-router/release/angular-ui-router.js"></script>
        <script src="bower_components/angular-resource/angular-resource.min.js"></script>
...
```

Add `ngResource` as a dependency in `public/app.js`.

*public/app.js*
```javascript
'use strict';

var retail = angular.module("retail", []);

angular
    .module('SampleApplication', [
        'appRoutes',
        'retail',
        'ngResource'
    ]);
```

Start up the application, head to `localhost:8081`, and check the development console.  If there are no errors then you're ready to move to the next step!

```shell
drf-sample/client$ node server.js
Use port 8081 to connect to this server
```

<a name="services"></a>
## Retail Services

According to the [AngularJS documentation on services](https://docs.angularjs.org/guide/services),

> Angular services are substitutable objects that are wired together using dependency injection (DI). You can use services to organize and share code across your app.

> Angular services are:

> Lazily instantiated – Angular only instantiates a service when an application component depends on it.

> Singletons – Each component dependent on a service gets a reference to the single instance generated by the service factory.

Long story short, services are individual modules of code that can be imported by other services, controllers, etc.  

For this application we're going to create three AngularJS services with the intended purpose to provide a way to query the Retail API.  Each service will focus on a specific API endpoint (`chains`, `stores`, and `employees`).

Let's start by adding three service files to the services directory.

```shell
components/
└── retail/
    ├── controllers/
    ├── services/
    │   ├── chain.service.js
    │   ├── store.service.js
    │   └── employee.service.js
    └── templates/
```

Add the following lines to each file.

*chain.service.js*
```javascript
retail
    .factory('Chain', function($resource) {
        return $resource(
            'http://localhost:8000/chains/:id/',
            {},
            {
                'query': {
                    method: 'GET',
                    isArray: true,
                    headers: {
                        'Content-Type':'application/json'
                    }
                }
            },
            {
                stripTrailingSlashes: false
            }
        );
    });
```

*store.service.js*
```javascript
retail
    .factory('Store', function($resource) {
        return $resource(
            'http://localhost:8000/stores/:id/',
            {},
            {
                'query': {
                    method: 'GET',
                    isArray: true,
                    headers: {
                        'Content-Type':'application/json'
                    }
                }
            },
            {
                stripTrailingSlashes: false
            }
        );
    });
```

*employee.service.js*
```javascript
retail
    .factory('Employee', function($resource) {
        return $resource(
            'http://localhost:8000/employees/:id/',
            {},
            {
                'query': {
                    method: 'GET',
                    isArray: true,
                    headers: {
                        'Content-Type':'application/json'
                    }
                }
            },
            {
                stripTrailingSlashes: false
            }
        );
    });
```

Then import the file into `index.html` `head` section so they can be used by the application.

```html
...
<script src="public/components/retail/services/chain.service.js"></script>
<script src="public/components/retail/services/store.service.js"></script>
<script src="public/components/retail/services/employee.service.js"></script>
...
```

Great, our three services have been defined and imported!  What do they do?  First, each service is defined as a `factory`.  An AngularJS `factory` typically defines one or more objects and returns those objects for direct use by the calling party.  In each of our factories, we are instantiating a `$resource` object and returning it directly.  Any module that injects our factories will have access to a pre-configured `$resource` object through the `factory`.

Each `$resource` object is defined with a set of [configurations](https://docs.angularjs.org/api/ngResource/service/$resource) explaining how to access our API endpoints.  For each, we are expecting the Django endpoint to live on `localhost:8000` and to be identified by either `/chains/`, `/stores/` or `/employees/`.  The extra `:id` parameter denotes that we can specify a resource ID and the ID will be plugged into the URI.

Next, we specify a `query` action.  This action peforms a `GET` request to the specified endpoint, expects an array in return, and ensures that the result is JSON.  

Finally, our Django application expects trailing slashes at the end of our requests so we ensure that those trailing slashes are not stripped.  

Our services are now ready to be used by another module.  The first module to make use of these services is the retail controller.

<a name="using-services"></a>
## Making Use of the Retail Services

The retail controller in the previous post was a very basic skeleton of what a controller can be.  While it is good to keep controllers light and move any heavy lifting to services, the original controller didn't serve much purpose.  Now that we have services defined, however, we can inject the services into the controller module to dynamically populate datasets based on the results of various API calls.

Open the retail controller and add the following code to the file.

*retail.control.js*
```javascript
retail
    .controller('RetailController', function($scope, Chain, Store, Employee) {
        Chain.query().$promise.then(function(data) {
            $scope.chains = data;
        });
        Store.query().$promise.then(function(data) {
            $scope.stores = data;
        });
        Employee.query().$promise.then(function(data) {
            $scope.employees = data;
        });
});
```

First, we injected the `Chain`, `Store` and `Employee` services into the controller.  Next, we use each of those services by calling their `query` actions and using the [promises](http://andyshora.com/promises-angularjs-explained-as-cartoon.html) the actions return to populate `$scope` variables of like-names.  

In essence, the controller making three `GET` requests to three different endpoints on the local retail API and populating variables once the results of each call have returned sucessfully.  

This is a very simple exmaple of how services can be used, but it's a great start for us to get API results into our client app!

<a name="template"></a>
## Displaying API Results in the Template

Lastly, we need to modify the retail template to make use of our shiny new controller `$scope` variables!  Add the following code to the retail template file.

**retail.template**
```html
<div ng-controller="RetailController">
  Chains
  <div ng-repeat="chain in chains">
      <div style="margin-left: 20px;">
          name: {{ chain.name }} <br/>
          description: {{ chain.description }} <br/>
          slogan: {{ chain.slogan }} <br/>
          founded_date: {{ chain.founded_date }} <br/>
          website: {{ chain.website }} <br/>
          <hr/>
      </div>
  </div>
  <br/>

  Stores
  <div ng-repeat="store in stores">
      <div style="margin-left: 20px;">
          chain: {{ store.chain }} <br/>
          number: {{ store.number }} <br/>
          address: {{ store.address }} <br/>
          opening_date: {{ store.opening_date }} <br/>
          business_hours_start: {{ store.business_hours_start }} <br/>
          business_hours_end: {{ store.business_hours_end }} <br/>
          <hr/>
      </div>
  </div>
  <br/>

  Employees
  <div ng-repeat="employee in employees">
      <div style="margin-left: 20px;">
          store: {{ employee.store }}  <br/>
          number: {{ employee.number }}  <br/>
          first_name: {{ employee.first_name }}  <br/>
          last_name: {{ employee.last_name }}  <br/>
          hired_date: {{ employee.hired_date }}  <br/>
      </div>
  </div>
  <br/>
</div>
```

This example is a bit more complex than the previous post, so let's go into what's happening here. 

[ng-repeat](https://docs.angularjs.org/api/ng/directive/ngRepeat) is a great AngularJS directive used to loop over collections and generate dynamic content within the looped elements.  Think of these as a Python `for` loop in syntax whereas the current element of the loop is defined as a subset of a collection.  In this case, we are looping other three lists - `chains`, `stores`, and `employees`.  These lists were defined within the retail controller from the previous section whereas each contains a list of results from their respective API call.  

When rendered, each list item will be displayed as a separate element `div` element.  Within the looped `div`, we are using the current item variable (`chain`, `store`, and `employee`) defined within the `ng-repeat` to interact with the data.  In this simple example the template will display the noteworthy fields of each object.

Everything is ready to go to start displaying the data!

<a name="running"></a>
## Running it All Together

Let's get the total application up and running!  Keep in mind that the intention of this guide is to run the Django application and the AngularJS application as two separate services.  To run everything together we need to run two different commands to start both sides:

**Start Django application**
```shell
tim@tim-XPS-13-9343:~/code/side/drf-sample/server$ python manage.py runserver
Performing system checks...

System check identified no issues (0 silenced).
January 02, 2017 - 18:52:56
Django version 1.8, using settings 'config.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
```

**Start AngularJS spplication**
```shell
tim@tim-XPS-13-9343:~/code/side/drf-sample/client$ node server.js 
Use port 8081 to connect to this server
```

Great!  Both applications are up and running.  Open a browser and head to `localhost:8081`.  Assuming you haven't cleared the Django database from [Part 2](/blog/getting-started-drf-angularjs-part-2/) you should see some data populated on the page!  If you did clear the database then you will have to populate your models through the ORM.  

Here's what my rendered page looks like!


<center>![map3](/images/drf-rendered.png)</center>


## Looking Forward

We now have a fully functional AngularJS application.  It's simple, yes, but it lays the foundation for the rest of the application.  Next time we can start utilizing the Retail API and displaying the API results for the user! 
