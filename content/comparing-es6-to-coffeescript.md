Title: Comparing ES2015 to Coffeescript - An Experiment
Date: 2015-11-19
Category: Javascript
Tags: javascript, coffeescript, es6, es2015
Slug: comparing-es2015-to-coffeescript-an-experiment
Author: Josh Finnie
Avatar: josh-finnie

At TrackMaven, we have been using [Coffeescript](http://coffeescript.org/) exclusively as our Javascript pre-compiler. We feel that it is easier to context switch between Python and Coffeescript due to the similarities in styles than it is to switch between Python and Javascript. And this has been working out fantastically for us; we have the ability to spin up backend engineers to work on the full-stack application without much training in the world of Javascript. However, the landscape of Javascript is changing.

## Why This Post?

With the introduction of ES2015, we have seen a lot of the good parts of Coffeescript being adopted into standard Javascript, and it begs the question: Should we stay with Coffeescript or start writing with the future of Javascript today? To help us answer that question, I did a little experiment with an example API Resource class. Below you will see examples of code written in a) Coffeescript b) Javascript that was transpiled through [js2.coffee](http://js2.coffee) c) ES2015 Javascript and d) Javascript that was trasnpiled through the [Babel.js Repl](https://babeljs.io/repl/).

With this experiment, I want to show how switching to ES2015 might 1) effect our outputted Javascript and 2) effect the efficiency we write pre-compiled Javascript.

### The Code

- [Coffeescript](#coffee)
- [Javascript compiled from Coffeescript](#js1)
- [ES6](#es6)
- [Javascript compiled from ES6](#js2)

## Conclusion

As you can see below, the generated Javascript (from both Coffeescript and ES2015) is very similar. I don't think we'd be losing anything in terms of readability of our generated Javascript. However, where the big difference is is still in the readablity of the pre-compiled code. I chose a very basic CRUD API class as our example and even with this simple example, I feel like I am haunted by the curly brackets.

I feel more than ever that ES2015 is going in the right direction; it is a huge leap down from where we currently are with JavaScript. And of course there are tons of benefits from getting away from Coffeescript and start writing ES2015, but right now I think we will be sticking with Coffeescript. This is mostly due to the fact that we would still need to transpile the code. One interesting thing that transpiling your code does give you, however, is the ability to use both! There is nothing stopping you from transpiling both your Coffeescript code **AND** your ES2015 code. This path is actually very interesting to me and I have been working on a way to do this (expect another blog post on this topic soon.)

What's your thoughts? Any users of Coffeescript make the jump to ES2015 successfully? Anyone think we're crazy with sticking with Coffeescript? Anyone using both Coffeescript and ES2015? Let us know below in the comments. Thanks!

Below is the code examples for this little experiment. Please feel free to browse, or jump directly to [the comments](#disqus_thread) to let us know your thought.

<a name="#coffee"></a>
### Coffeescript <small>[back to top](#top)</small>

<span id="coffeescript">
```coffeescript
angular.module 'common.services' 

.factory 'APIResource', ($q, $log, $http, Model) ->
    class APIResource extends Model
        baseUrl: "api/v1"

        get: (resourceId,params = null) ->
            deferred = $q.defer()
            fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/"
            args = {method:'GET', url:fullUrl}
            if params
                args['params'] = params

            $http(args)
                .success (data) =>
                    deferred.resolve(data)
                .error (data) =>
                    deferred.reject(data)

            return deferred.promise

        update: (resourceId, data) ->
            deferred = $q.defer()
            fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/"

            $http({method:'PUT', url:fullUrl, data:data})
                .success (data) =>
                    deferred.resolve(data)
                .error (data) =>
                    deferred.reject(data)

            return deferred.promise

        create: (data) ->
            deferred = $q.defer()
            fullUrl = "/#{@baseUrl}/#{@resourceUrl}/"

            $http({method:'POST', url:fullUrl, data:data})
                .success (data) =>
                    deferred.resolve(data)
                .error (data) =>
                    deferred.reject(data)

            return deferred.promise

        delete: (resourceId) ->
            deferred = $q.defer()
            fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/"

            $http({method:'DELETE', url:fullUrl})
                .success (data) =>
                    deferred.resolve(data)
                .error (data) =>
                    deferred.reject(data)

            return deferred.promise
```
</span>

<a name="js1"></a>
### Javascript compiled from Coffeescript <small>[back to top](#top)</small>

```javascript
var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

angular.module('common.services').factory('APIResource', function($q, $log, $http, Model) {
  var APIResource;
  return APIResource = (function(superClass) {
    extend(APIResource, superClass);

    function APIResource() {
      return APIResource.__super__.constructor.apply(this, arguments);
    }

    APIResource.prototype.baseUrl = "api/v1";

    APIResource.prototype.get = function(resourceId, params) {
      var args, deferred, fullUrl;
      if (params == null) {
        params = null;
      }
      deferred = $q.defer();
      fullUrl = "/" + this.baseUrl + "/" + this.resourceUrl + "/" + resourceId + "/";
      args = {
        method: 'GET',
        url: fullUrl
      };
      if (params) {
        args['params'] = params;
      }
      $http(args).success((function(_this) {
        return function(data) {
          return deferred.resolve(data);
        };
      })(this)).error((function(_this) {
        return function(data) {
          return deferred.reject(data);
        };
      })(this));
      return deferred.promise;
    };

    APIResource.prototype.update = function(resourceId, data) {
      var deferred, fullUrl;
      deferred = $q.defer();
      fullUrl = "/" + this.baseUrl + "/" + this.resourceUrl + "/" + resourceId + "/";
      $http({
        method: 'PUT',
        url: fullUrl,
        data: data
      }).success((function(_this) {
        return function(data) {
          return deferred.resolve(data);
        };
      })(this)).error((function(_this) {
        return function(data) {
          return deferred.reject(data);
        };
      })(this));
      return deferred.promise;
    };

    APIResource.prototype.create = function(data) {
      var deferred, fullUrl;
      deferred = $q.defer();
      fullUrl = "/" + this.baseUrl + "/" + this.resourceUrl + "/";
      $http({
        method: 'POST',
        url: fullUrl,
        data: data
      }).success((function(_this) {
        return function(data) {
          return deferred.resolve(data);
        };
      })(this)).error((function(_this) {
        return function(data) {
          return deferred.reject(data);
        };
      })(this));
      return deferred.promise;
    };

    APIResource.prototype["delete"] = function(resourceId) {
      var deferred, fullUrl;
      deferred = $q.defer();
      fullUrl = "/" + this.baseUrl + "/" + this.resourceUrl + "/" + resourceId + "/";
      $http({
        method: 'DELETE',
        url: fullUrl
      }).success((function(_this) {
        return function(data) {
          return deferred.resolve(data);
        };
      })(this)).error((function(_this) {
        return function(data) {
          return deferred.reject(data);
        };
      })(this));
      return deferred.promise;
    };

    return APIResource;

  })(Model);
});

// ---
// generated by coffee-script 1.9.2
```

__Note__: This javascript was compiled from the above Coffeescript using [js2.coffee](http://js2.coffee).

<a name="es6"></a>
### ES6 (ES2015) Javascript <small>[back to top](#top)</small>

```javascript
angular.module('common.services')

.factory('APIResource', function ($q, $log, $http, Model) {
    class APIResource extends Model {
        constructor () {
            super();
            this.baseUrl = "api/v1";
        }
        
        get (resourceId, params = null) {
            let deferred = $q.defer();
            let fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";
            let args = {method:'GET', url:fullUrl}
            if (params) {
                args['params'] = params
            }

            $http(args)
                .success((data) => {
                    deferred.resolve(data);
                })
                .error((data) => {
                    deferred.reject(data);
                });

            return deferred.promise;
        }

        update (resourceId, data) {
            let deferred = $q.defer();
            let fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";

            $http({method:'PUT', url:fullUrl, data:data})
                .success((data) => {
                    deferred.resolve(data);
                })
                .error((data) => {
                    deferred.reject(data);
                });

            return deferred.promise;
        }

        create (data) {
            let deferred = $q.defer();
            let fullUrl = "/#{@baseUrl}/#{@resourceUrl}/";

            $http({method:'POST', url:fullUrl, data:data})
                .success((data) => {
                    deferred.resolve(data);
                })
                .error((data) => {
                    deferred.reject(data);
                });

            return deferred.promise;
        }

        delete (resourceId) {
            let deferred = $q.defer();
            let fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";

            $http({method:'DELETE', url:fullUrl})
                .success((data) => {
                    deferred.resolve(data);
                })
                .error((data) => {
                    deferred.reject(data);
                });

            return deferred.promise;
        }
    }
});
```

<a name="js2"></a>
### Javascipt compiled from ES6 <small>[back to top](#top)</small>

```javascript
'use strict';

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

angular.module('common.services').factory('APIResource', function ($q, $log, $http, Model) {
    var APIResource = (function (_Model) {
        _inherits(APIResource, _Model);

        function APIResource() {
            _classCallCheck(this, APIResource);

            _Model.call(this);
            this.baseUrl = "api/v1";
        }

        APIResource.prototype.get = function get(resourceId) {
            var params = arguments.length <= 1 || arguments[1] === undefined ? null : arguments[1];

            var deferred = $q.defer();
            var fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";
            var args = { method: 'GET', url: fullUrl };
            if (params) {
                args['params'] = params;
            }

            $http(args).success(function (data) {
                deferred.resolve(data);
            }).error(function (data) {
                deferred.reject(data);
            });

            return deferred.promise;
        };

        APIResource.prototype.update = function update(resourceId, data) {
            var deferred = $q.defer();
            var fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";

            $http({ method: 'PUT', url: fullUrl, data: data }).success(function (data) {
                deferred.resolve(data);
            }).error(function (data) {
                deferred.reject(data);
            });

            return deferred.promise;
        };

        APIResource.prototype.create = function create(data) {
            var deferred = $q.defer();
            var fullUrl = "/#{@baseUrl}/#{@resourceUrl}/";

            $http({ method: 'POST', url: fullUrl, data: data }).success(function (data) {
                deferred.resolve(data);
            }).error(function (data) {
                deferred.reject(data);
            });

            return deferred.promise;
        };

        APIResource.prototype['delete'] = function _delete(resourceId) {
            var deferred = $q.defer();
            var fullUrl = "/#{@baseUrl}/#{@resourceUrl}/#{resourceId}/";

            $http({ method: 'DELETE', url: fullUrl }).success(function (data) {
                deferred.resolve(data);
            }).error(function (data) {
                deferred.reject(data);
            });

            return deferred.promise;
        };

        return APIResource;
    })(Model);
});
```

__Note__: This Javascript was compiled from the above ES6 Javascript using the [Babel.js Repl](https://babeljs.io/repl/).
