Title: Getting Started with Django REST Framework (DRF) and AngularJS (Part 2)
Date: 2016-01-11
Category: Development
Tags: django, django rest framework, angularjs
Slug: getting-started-drf-angularjs-part-2
Author: Tim Butler
Avatar: tim-butler

__Read: [Part 1 - Initial Project Setup](/blog/getting-started-drf-angularjs-part-1/)__
__Write: [Part 2 Supplementary Code](https://github.com/TrackMaven/getting-started-with-drf-angular/tree/part-2)__

This is the second post in a multi-part series geared toward getting started with Django Rest Framework (DRF) and AngularJS.  The goal of this series is to create an extensive, RESTful web application that uses DRF in the server and AngularJS in the client.

This post focuses on Django, with topics covering

* [A Description of Our Series Project](#project-description)
* [Adding a new Project Module](#module-creation)
* [Defining Database Models](#model-definition)
* [Migrating Database Models](#migrations)
* [Creating Model Data via the Django ORM](#object-creation)

We will be using Django `1.8.5` and Django Rest Framework `3.3.0`.  The base directory for our project is named `drf-sample`.

<a name="project-description"></a>
## A Description of Our Series Project

This post begins to outline code that we will be contributing to throughout this series.  You are welcome to create your own project following the ideas and strategies talked about here, but for the purpose of consistency within the series we will be making a single project and adding to it over time.

Our project is an employee management system for retail chains.  We will need to keep track of multiple retail chains (their name, slogan, website, etc.), each store location within the chain (store number, opening date, address, etc.) and the employees within each store (employee number, name, starting date, etc.).  Each store location may be associated with only a single chain and each employee may work at only a single store at a time.

Throughout the series, we will create an underlying database for our project, an API to access our data securely from external sources, and single-page app interface that reads and modifies the data.  Of course, these are very high-level requirements and the scope of this project will grow as the series continues!create

<a name="module-creation"></a>
## Adding a New Project Module
Before we begin coding, we need to create a new module within our project.  Since our project is geared toward retail management, we will name the module `retail`.

To create a new module within our Django project, we need to:

* Create a new directory within the project structure
* Add the new directory to the list of Djangos installed applications.

First, add the `server/retail/` directory to the project.

```
drf_sample/
├── client
└── server
    ├── retail
    │   └── __init__.py
    ├── config
    ├── __init__.py
    ├── manage.py
    └── urls.py
```

*Note: Do not forget to create a `__init__.py` file inside the new directory.  It will not be recognized as a module without this file.*

Next, we need to ensure that our project knows that the new directory is meant to be an application module.  The `server/config/settings.py` file contains an `INSTALLED_APPS` setting which lists of all modules recognized by the project.  A module will only be recognized by the project if it has been included in this setting.  Add the `retail` module to `INSTALLED_APPS` by including the directory name in the list.

```python
INSTALLED_APPS = (
    ...,
    'retail'
)
```

Django will now use the `retail` directory to associate code with the `retail` application module.

Let's start coding the module!

<a name="model-definition"></a>
## Defining Database Models
Generally, the first step in coding a new module is to create a database schema for the module data using Django `Models`.  `Models` are classes that Django translates into an underlying relational database tables.  Have no fear; developers very rarely need to worry using SQL to interact with the database.  Instead, interactions with the tables are handled through the Django ORM (more on this later).

For our module, we want to define three models:  `Chain` and `Store`, and `Employee`.  These models are fairly straight forward:

* `Chain` represents a retail chain at a very high level (Target, for example).
* `Store` represents a single store location of a `Chain` (a single Target location).
* `Employee` represents an individual person working at a `Store` (John Doe, the cashier).

To add `models` to the new module, create a `server/retail/models.py` file and add the following code.

```python
from django.db import models
from django.utils import timezone
from django.core.validators import MaxValueValidator, MinValueValidator


class Chain(models.Model):
    """ High-level retail chain model"""
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=1000)
    slogan = models.CharField(max_length=500)
    founded_date = models.CharField(max_length=500)
    website = models.URLField(max_length=500)


class Store(models.Model):
    """ Store location model.  Foreign key to Chain."""
    chain = models.ForeignKey(Chain)
    number = models.CharField(max_length=20)
    address = models.CharField(max_length=1000)
    opening_date = models.DateTimeField(default=timezone.now)

    # Business hours in a 24 hour clock.  Default 8am-5pm.
    business_hours_start = models.IntegerField(
        default=8,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(23)
        ]
    )
    business_hours_end = models.IntegerField(
        default=17,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(23)
        ]
    )


class Employee(models.Model):
    """ Location employee model.  Foreign key to Store."""
    store = models.ForeignKey(Store)
    number = models.CharField(max_length=20)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    hired_date = models.DateTimeField(default=timezone.now)

```

The above code may seem a bit complicated at first, so let's go through what it all means.

Each `Model` class defines what will become a table in the underlying database and class attributes define columns within the associated table.  Each class attribute is as a [Django Model field type](https://docs.djangoproject.com/en/1.8/ref/models/fields/#field-types) specifying the column data type along with optional type-specific parameters (such as the maximum length of a character field).  Field types correspond to common SQL column data types, including characters, integers, boolean fields, and date/times.

The `ForeignKey` field type creates a one-to-many relationship between two models.  In the code above, the `Store` model contains a `ForeignKey` to the `Chain` model.  This means an instance of `Store` can be associated with a single `Chain` object, but a `Chain` can be associated with many `Stores`.  Likewise, an instance of `Employee` can be associated with a single `Store` object, but a `Store` may be associated with several `Employees`.

It is best to keep table and column names relevant to the data they store, so make sure that your models and fields follow that same rule.

<a name="migrations"></a>
## Migrating Database Models
We have defined our Django `Models` to represent the database we want, but we have not used them to create the underlying database schema.  To create our database we will use Django [Migrations](https://docs.djangoproject.com/en/1.8/topics/migrations/).  Migrations are a way of synchronizing the database schema with the state of your project `Models`.

To run the first project migration, run the following two commands from the project root directory:

* `python server/manage.py makemigrations retail`
* `python server/manage.py migrate`

<pre>
drf-sample$ python server/manage.py makemigrations retail
Migrations for 'retail':
  <strong>0001_initial.py:
    - Create model Chain
    - Create model Employee
    - Create model Store</strong>
    - Add field store to employee
</pre>
<pre>
drf-sample$ python server/manage.py migrate
Operations to perform:
  Synchronize unmigrated apps: staticfiles, messages
  Apply all migrations: admin, contenttypes, retail, auth, sessions
Synchronizing apps without migrations:
  Creating tables...
    Running deferred SQL...
  Installing custom SQL...
Running migrations:
  Rendering model states... DONE
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying contenttypes.0002_remove_content_type_name... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying auth.0003_alter_user_email_max_length... OK
  Applying auth.0004_alter_user_username_opts... OK
  Applying auth.0005_alter_user_last_login_null... OK
  Applying auth.0006_require_contenttypes_0002... OK
  <strong>Applying retail.0001_initial... OK</strong>
  Applying sessions.0001_initial... OK
</pre>
*Note: For the purpose of this guide, do not worry about manually creating a database.  By default, Django creates a `db.sqlite3` file containing a local SQL DB to be used by the project.*

Excellent, let's go over the output from the commands.  During the first command, we can see that a migration file is created, `retail.0001_initial`, and three `models` were created in the file:

* `Create model Chain`
* `Create model Employee`
* `Create model Store`

During the second command, the migration file is applied.  This means our tables have been created in the database!

The output also shows a lot of other migrations.  Django requires a few models to run correctly.  Do not worry about these other migrations for now.  Just know that they are used internally by Django and for user permissions.

That is all we need to do with our models for now!  Whenever a `retail` model changes, such as when a new field is added to a model, the above migration commands must be executed again to ensure that the underlying database is kept up to date with the updated model definition.

*Note: The `makemigrations` command creates a `migrations` directory in the `retail` module.  This new directory holds versioned migration files keeping track of all model changes over time.  The `migrate` command executes all migrations within the directory __in order__ to ensure consistent results.*

<a name="object-creation"></a>
## Creating Model Data via the Django ORM
Tables without data are not very interesting.  Let's take a moment to go over the Django ORM and add objects to our models.

To interact with the Django ORM, we can use the Django shell.  The Django shell opens a Python interactive shell that sets the `DJANGO_SETTINGS_MODULE` environment variable allowing use of our `server/config/settings.py` file configurations.  Otherwise, the Django shell is everything you'd expect from a normal python shell.

To open the Django shell, run the `python server/manage.py shell` command from the project root folder.

```
$ python server/manage.py shell
Python 2.7.6 (default, Jun 22 2015, 17:58:13)
[GCC 4.8.2] on linux2
Type "help", "copyright", "credits" or "license" for more information.
(InteractiveConsole)
>>>
```

First, interact with the `Chain` model.  Import `Chain` and create an instance of the `Chain` model with all column values filled in.

```
>>> from retail.models import Chain
>>> chain = Chain(name="Cafe Amazing", description="Founded to serve the best sandwiches.", slogan="The best cafe in the USA!", founded_date="2014-12-04T20:55:17Z", website="http://www.thecafeamazing.com")
>>>
```

Instantiating an object does not automatically save the object to the database.  A Django model must be explicitly saved before its data is committed.

```
>>> chain.save()
>>>
```

Great!  Now we have created a `Chain` object and stored it in the database!  It's as easy as that.  We check that the object was created as expected by querying from the database using the Django database API.  From the Django shell, model objects can be queried using the format `<model_class>.objects.<query_type>`.  For example, to query for all `Chain` objects, we can use `Chain.objects.all()`.

```python
>>> Chain.objects.all()
[<Chain: Chain object>]
>>>
```

The result of `.all()` returns a list of all objects of the specified model type.  From the output, it looks likes we have a list of one object!  Let's make sure that object is what we previously saved.

```python
>>> chain = Chain.objects.all()[0]  # store the first object in the list of Chains
>>> chain.id
1
>>> chain.name
'Cafe Amazing'
>>> chain.description
'Founded to serve the best sandwiches.'
>>> chain.slogan
'The best cafe in the USA!'
>>> chain.founded_date
'2014-12-04T20:55:17Z'
>>> chain.website
'http://www.thecafeamazing.com'
>>>
```
*Note: By default, Django applies an `ID` to the model object when saved to the database.  This becomes the primary key of the object within the model type.*

More on querying objects through the Django shell can be found in the [Making Queries documentation](https://docs.djangoproject.com/en/1.8/topics/db/queries/).

Next, let's make a `Store` object that is a member of the `Chain` we previously created.  Remember that the `Store` model object needs a reference to a `Chain`, so we must pass it a saved `Chain` object.  We can use a `.get(name='Cafe Amazing')` query to retrieve the desired `Chain` object based on chain name.

```python
>>> chain = Chain.objects.get(name='Cafe Amazing')
>>> from retail.models import Store
>>> store = Store(chain=chain, number="AB019", address="1234 French Quarter Terrace Columbia MD", opening_date="2015-12-04T22:55:17Z")
>>> store.save()
>>> Store.objects.all()[0].number
u'AB019'
>>>
```

Finally, let's make an Employee object.  Remember that we must provide it a saved `Store` reference and we can use a `.get(number='AB019')` query to retrieve the desired `Store` object based on store number.

```python
>>> store = Store.objects.get(number='AB019')
>>> from retail.models import Employee
>>> employee = Employee(store=store, number="026546", first_name="John", last_name="doe", hired_date="2015-12-04T00:00:00Z")
>>> employee.save()
>>> Employee.objects.all()[0].number
u'026546'
>>>
```

Look great!  We have now created three objects within our database.

## Looking Forward

A lot was covered in this post so this is a great point to end on.  Look for the next post soon, covering API endpoint creation, including views, serializers, and URL routing for the `Retail` application.
