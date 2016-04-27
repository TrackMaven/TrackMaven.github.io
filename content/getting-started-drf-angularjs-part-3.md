Title: Getting Started with Django REST Framework (DRF) and AngularJS (Part 3)
Date: 2016-04-27
Category: Development
Tags: django, django rest framework, angularjs
Slug: getting-started-drf-angularjs-part-3
Author: Tim Butler
Avatar: tim-butler

__Read: [Part 1 - Initial Project Setup](/blog/getting-started-drf-angularjs-part-1/)__ and [Part 2 - Django Models and the ORM](/blog/getting-started-drf-angularjs-part-2/)

__Write: [Part 3 Supplementary Code](https://github.com/TrackMaven/getting-started-with-drf-angular/tree/part-3)__

This is the third installment in a multi-part series geared toward getting started with Django Rest Framework (DRF) and AngularJS.  The goal of this series is to create an extensive, RESTful web application that uses DRF in the server and AngularJS in the client.

This post focuses on the basics of Django REST Framework (DRF), with topics covering

* [On the Topic of Serializers, Views, and Routes](#about)
* [Serializers](#serializers)
* [Views](#views)
* [URL Routing](#routing)
* [Using the API](#api)

This guide uses Django `1.8.5` and Django Rest Framework `3.3.0`.  The base directory for our project is named `drf-sample`.

## A Recap and Introduction
Last we met, we setup a `Retail` module, created models for the module, setup the module database, and explored the ORM to create an initial set of objects in the database.  While it's great to have our database setup, we don't have a way to access the data from outside the application.  

Remember, our project goal is to create a client application that is deployed separately from the server application.  For this to work, we need to create an API on the server for the client to interact with.  Django REST Framework (DRF) provides us with the tools to make the API.  

*At a high level, we can think of our server application as a house.  Django is the house itself and all the various furniture inside the house.  Normally, only those inside the house are able to see how the house is furnished.  However, DRF provides a windows and doors for the house.  With DRF, outsiders can look inside the house and add or remove furniture.*

While DRF can become quite extensive, this post will focus on the basics in terms of a single goal: expose our Django models to external services via an API.  For this, we need to define three things:

* `Serializers` to specify how the database objects are validated and formatted when accessed from the API
* `Views` to specify which operations can be performed on models through the API
* `routes` to specify how to access each of the database models through the API

By the end of this post, we will be able to send API requests to the `Retail` application and retrieve our previously created data objects.  

<a name="serializers"></a>
## Defining Serializers
A `serializer` translates objects into different formats.  From the [DRF serializer documentation](http://www.django-rest-framework.org/api-guide/serializers/): 

> Serializers allow complex data such as querysets and model instances to be converted to native Python datatypes that can then be easily rendered into JSON, XML or other content types. Serializers also provide deserialization, allowing parsed data to be converted back into complex types, after first validating the incoming data.

Imagine the `Retail Store` model.  `Store` contains the `opening_date` `DateTimeField`.  In the underlying database the field is stored in some sort of database date field (depending on the database chosen), but that format may not always be human-readible.  Instead, when a user views a date they want an ISO formatted date string in the vein of `2014-12-04T20:55:17Z`.  `Serializers` aid in this translation.

We need a `serializer` for each of our three models: `Chain`, `Store`, and `Employee`.  Add the `server/retail/serializers.py` file to the project.  

```
drf_sample/
├── client
└── server
    ├── config
    ├── manage.py
    └── retail
        ├── __init__.py
        ├── migrations
        ├── models.py
        ├── serializers.py
        └── views.py
```

Add the following code to `serializers.py`.

```python
from rest_framework import serializers
from retail.models import Chain, Store, Employee


class ChainSerializer(serializers.ModelSerializer):
    """ Serializer to represent the Chain model """
    class Meta:
        model = Chain
        fields = ("name", "description", "slogan", "founded_date", "website")


class StoreSerializer(serializers.ModelSerializer):
    """ Serializer to represent the Store model """
    class Meta:
        model = Store
        fields = (
            "chain", "number", "address", "opening_date",
            "business_hours_start", "business_hours_end"
        )


class EmployeeSerializer(serializers.ModelSerializer):
    """ Serializer to represent the Employee model """
    class Meta:
        model = Employee
        fields = ("store", "number", "first_name", "last_name", "hired_date")
```

The above code defines three `ModelSerializers`, a class associated directly with an existing Django model.  The `ModelSerializer` `Meta class` allows us to specify the model we wish to associate with the serializer and the model fields the serializer may access.

For our `Retail` application, we will be utilizing these serializers through API `views`, defined later.  They can be used in other contexts as well.  For example, in the shell we can use a serializer to represent a model object as a dictionary:

``` 
drf-sample$ python server/manage.py shell

>>> from retail.models import Chain
>>> from retail.serializers import ChainSerializer
>>> chain = Chain.objects.first()
>>> serializer = ChainSerializer(chain)
>>> serializer.data
{'website': u'http://www.thecafeamazing.com', 'founded_date': u'2014-12-04T20:55:17Z', 'slogan': u'The best cafe in the USA!', 'name': u'Cafe Amazing', 'description': u'Founded to serve the best sandwiches.'}
```

Once we instantiate a serializer with a model object (in this case a `Chain` object), the `data` attribute of the serializer contains a dictionary version of the object.  Continuing from above, we can modify the dictionary and save the new object in the database using the following:

```
>>> data = serializer.data
>>> data['slogan'] = 'The best cafe in the Mississippi!'
>>> serializer = ChainSerializer(chain, data=data)
>>> serializer.is_valid()
True
>>> new_chain = serializer.save()
>>> new_chain.slogan
u'The best cafe in the Mississippi!'
```

For this example, we instantiate the serializer with an existing object and the new dictionary representation of the object.  `is_valid` determines whether or not the data dictionary can be correctly formatted into the database fields for the model.  If it can, we can perform a `save` to update the model object based the new data.

**Note:  The `is_valid` check must be performed before a `save` can be executed.**

For the purposes of this post, all of these functions will be performed by interactions between our `serializers` and our `views`.  We are not responsible for explicitly serializing objects.  Phew!

<a name="views"></a>
## Defining Views
Now, we need a way for our application to define how our model data can be interacted with. Whether it be a query to a single model object or adding a new object, `views` define which operations can be performed.

A view controls all operations an external eneity may perform on our model objects through the API.  These operations are usually referred to as `CRUD` operations corresponding to...

* `Create`: Add a new, distinct object to the database
* `Retrieve`: Query a list of objects or a single object from the database
* `Update`: Edit an existing object in the database
* `Delete`: Remove an existing object from the database

Views also provide other functions, including, but not limited to...

* Authentication: identifies the credentials that a request is made with
* Permissioning: determines if a request is allowed
* Filtering: filters object results based on specified parameters

To start working on our `Retail` views, add the `server/retail/views.py` file to the project.

```
drf_sample/
├── client
└── server
    ├── config
    ├── manage.py
    └── retail
        ├── __init__.py
        ├── migrations
        ├── models.py
        ├── serializers.py
        └── views.py
```

Add the following code to `views.py`.

```
from rest_framework import viewsets
from retail.models import Chain, Store, Employee
from retail.serializers import ChainSerializer, StoreSerializer,EmployeeSerializer


class ChainViewSet(viewsets.ModelViewSet):
    """ ViewSet for viewing and editing Chain objects """
    queryset = Chain.objects.all()
    serializer_class = ChainSerializer


class StoreViewSet(viewsets.ModelViewSet):
    """ ViewSet for viewing and editing Store objects """
    queryset = Store.objects.all()
    serializer_class = StoreSerializer


class EmployeeViewSet(viewsets.ModelViewSet):
    """ ViewSet for viewing and editing Employee objects """
    queryset = Employee.objects.all()
    serializer_class = EmployeeSerializer

```

The above code defines three `ModelViewSets`, a class that comes pre-packaged with all `CRUD` operations and connects directly to an existing model.  The `queryset` attribute specifies a very basic query that acting as the base set of objects the view has access to.  Our views are allowed access to all of their model objects.  The `serializer_class` attribute specifies which serializer will be used to format individual objects within the `queryset` when requests are made.

In the example above, each `ViewSet` corresponds to its named model types:

* `ChainViewSet` uses a queryset for the `Chain` model (`Chain.objects.all()`)
* `StoreViewSet` uses a queryset for the `Store` model (`Store.objects.all()`)
* `EmployeeViewSet` uses a queryset for the `Employee` model (`Employee.objects.all()`)

Likewise, each `ViewSet` corresponds to its named serializer:

* `ChainViewSet` uses the `ChainSerializer`
* `StoreViewSet` uses the `StoreSerializer`
* `EmployeeViewSet` uses the `EmployeeSerializer`

Very simply put, the `ChainViewSet` allows all `CRUD` operations to be performed on all `Chain` objects, and so on.  

<a name="routing"></a>
## Defining URL Routes
We have the views in place to allow `CRUD` operations on our models, but we haven't defined how to access those operations through the API.  This is where `Routes` comes in.

`Routes` define Uniform Resource Identifiers (URIs) that can be accessed through the API.  External services can interact with these URIs communicate with our application and perform operations on our model objects.

We need to define a `Route` for each model type.  We already have a `server/urls.py` file in our project in anticipation of our routes.  Add the following code to that file:

```python
from rest_framework.routers import DefaultRouter
from retail.views import ChainViewSet, StoreViewSet, EmployeeViewSet

router = DefaultRouter()
router.register(prefix='chains', viewset=ChainViewSet)
router.register(prefix='stores', viewset=StoreViewSet)
router.register(prefix='employees', viewset=EmployeeViewSet)

urlpatterns = router.urls
```

The code above defines a DRF `DefaultRouter` and registers a URI for each of our Models along with the view that the URI provides access to.  `settings.py` points to the `urls.py` file (via the `ROOT_URLCONF` setting).  Django expects to find a `urlpatterns` variable here specifying all the registered URIs that can be accessed through the API, so we added all of our registered URIs.  

<a name="api"></a>
## Using the API
We now have all the pieces in place to access our server database through the API.  Cool, but what does it mean and how do we do it?  Once we run the server, we can query our server database with an API request tool by appending `/chains/`, `/stores/` or `/employees/` to the base application server URL (`localhost:8000 by default`) to access our models!

Let's start the application:

```
drf-sample$ python server/manage.py runserver
Performing system checks...

System check identified no issues (0 silenced).
April 27, 2016 - 17:42:21
Django version 1.8, using settings 'config.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
```

With the server running we can use an API request tool, such as [cURL](https://curl.haxx.se/), to run queries on our server database.

```
drf-sample$ curl -g localhost:8000/chains/
[{"name":"Cafe Amazing","description":"Founded to serve the best sandwiches.","slogan":"The best cafe in the Mississippi!","founded_date":"2014-12-04T20:55:17Z","website":"http://www.thecafeamazing.com"}]
```

*Note: cURL usage is beyond the scope of this post, but documentation can be found around the internet.*

The result is a list of dictionaries with a single item representing our `Chain` object defined previously!

Let's try querying for `Store` and `Employee` objects.

```
drf-sample$ curl -g localhost:8000/stores/
[{"chain":1,"number":"AB019","address":"1234 French Quarter Terrace Columbia MD","opening_date":"2015-12-04T22:55:17Z","business_hours_start":8,"business_hours_end":17}]

drf-sample$ curl -g localhost:8000/employees/
[{"store":1,"number":"026546","first_name":"John","last_name":"doe","hired_date":"2015-12-04T00:00:00Z"}]
```

Great, the API works!  The above commands only perform `GET` requests, but our `ViewSet` definitions are defined in a way to allow all operations for anyone accessing our server.  Permission filters can be added the `ViewSets` to allow only certain users to the server or specify only specific operations, but that will be covered in another post.

## Looking Forward

We got an API up and working for the server!  The next post will cover the basics of AngularJS and how to connect the client code to the server.