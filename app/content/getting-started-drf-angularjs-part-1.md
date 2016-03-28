Title: Getting Started with Django REST Framework (DRF) and AngularJS (Part 1)
Date: 2015-11-10
Category: Development
Tags: django, django rest framework, angularjs
Slug: getting-started-drf-angularjs-part-1
Author: Tim Butler
Avatar: tim-butler

This is the first section in a series about getting started with [Django](https://www.djangoproject.com/), [Django REST Framework (DRF)](http://www.django-rest-framework.org/) and [AngularJS](https://angularjs.org/).  The goal of this series to to create an extensive, RESTful web application that uses Django and Django REST Framework as the server application and AngularJS for the client application.  We will not be using Django templates here; our front- and back-end applications will be separate entities.

For this project, we will be using Django `1.8.5` and Django REST Framework `3.3.0`.  Further, this guide assumes you have installed standard python development tools and [virtualenvwrapper](https://virtualenvwrapper.readthedocs.org/en/latest/).

## Goals of this Section

This section focuses on Django, covering the following topics:

* [Brief introduction to Django, Django REST Framework, and AngularJS](#introduction)
* [Initial project setup and creation](#project-creation)
* [Folder structure modification to support both front- and back-end development](#folder-structure)

<a name="introduction"></a>
## A Brief Introduction: Django, DRF and AngularJS

RESTful APIs have become increasingly popular among modern web applications since they provide a standard means to interact with resources across applications.  Conforming to RESTful constraints can create web applications that are both high-performing and maintainable.  The Django and DRF frameworks provide developers with fast and secure ways to create RESTful web applications packed full of useful features, such as an extensive ORM, serialization, custom authentication and permissions classes, and browsable APIs among others.

Think of Django as the database manager for your server.  The Django ORM provides powerful ways to locally setup and manage database tables and the data within them.  DRF is the external window into your database.  DRF provides the means to create powerful APIs to access application data while allowing developers to customize permissions, authentication, filtering, and more.  AngularJS if a front-end framework that provides two-way data binding between HTML and Javascript to dynamically display data.

At TrackMaven, we use Django and DRF as the main backend frameworks for our web application development and AngularJS for front-end development.  Through these, we find that web application development is both straight-forward and extensible enough to fit into our growing demands while maintaining RESTful principles.

<a name="project-creation"></a>
## Setting up a New Project
### Creating an Initial Project

Getting started with Django and DRF is quite easy.  Django provides a startup script that builds a starter project with default configurations, an initial `/admin/` API endpoint, and a management command file for running the application.

To start, let's create a virtual environment for our sample project and download our required packages.

```shell
$ mkvirtualenv drf-sample
$ pip install django==1.8.5
$ pip install djangorestframework==3.3.0
```

Within the virtual environment, we can run the Django start-up script to create a new project named `drf_sample`

```
$ django-admin startproject drf_sample
```

We now have a new project folder named `drf_sample` with the following structure:
```
drf_sample/
├── drf_sample
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```
Cool, but what do these files actually do?

<dl>
  <dt>settings.py</dt>
  <dd style="padding: 0 0 10px 25px;">Contains Django/DRF settings and specifies where various project modules are located.  Additional information on the file can be found in the <a href="https://docs.djangoproject.com/en/1.8/topics/settings/">Django Settings documentation</a></dd>
  <dt>urls.py</dt>
  <dd style="padding: 0 0 10px 25px;">The URL dispatcher for the project API.  Pre-loaded with an <em>/admin/</em> endpoint for project administration.</dd>
  <dt>wsgi.py</dt>
  <dd style="padding: 0 0 10px 25px;">Uses <a href="http://wsgi.readthedocs.org/en/latest/">WSGI</a> to define the runnable application server.</dd>
  <dt>manage.py</dt>
  <dd style="padding: 0 0 10px 25px;">Provides command-line options for administrators to setup/run the application server and sync the database with our Django model definitions.  More information on this file can be found in the <a href="https://docs.djangoproject.com/en/1.8/ref/django-admin/">Django Admin documentation</a></dd>
</dl>

<a name="folder-structure"/></a>
## Fitting the Directory Structure to our Needs
The default Django project folder structure is quite minimal and doesn't give us an easy way to organize server code vs client code within the same project.  Remember, our goal is to create a web application that supports both server and client as two separate applications within the same project, so a differentiation between server and client code is preferred.

Why use separate applications?  Simple answer: cleaniless, decoupling and consistency.

- Keeping the server and client code separate makes for a cleaner development environment.
- Other than the API contract ensured by the server, the code for the front- and back-end contains little-to-no dependencies between each other.  If the server goes down, the client can still function and report an outtage if necessary.
- Our server application provides a specific contract as to how data within the server can be accessed.  The client will use that contract to access the data it needs to display on the front-end.  All other applications accessing server data will use the same contract.  Server data access remains consistent irregardless of the application accessing the data.

#### Update the Directory Structure
Let's modify the default project folder structure to support our separate applications.  The modified folder structure should look like the following:
```
drf_sample/
├── client
└── server
    ├── config
    │   ├── __init__.py
    │   ├── settings.py
    │   └── wsgi.py
    ├── __init__.py
    ├── manage.py
    └── urls.py
```
*Note: At this point, our `__init__.py` files are blank, so create them where necessary.*

The updated structure separates our newly created Django server project from our future development space for the AngularJS client.  All Django and DRF development is done in the `server` directory while all front-end AngularJS development is done in the `client` directory.

#### Fix the Default Module Links
Various parts of a Django application need to link to other modules within the project.  The default project setup used default links based on the original project structure.  Modifying the structure has caused those links to break.  Moving forward, we will ensure that all new module links conform to the new directory structure, but the current broken links must be fixed before we move on.  The following line changes will fix our issues:

*In server/config/settings.py*
```python
ROOT_URLCONF = 'urls'
    changes to
ROOT_URLCONF = 'server.urls'

WSGI_APPLICATION = 'wsgi.application'
    changes to
WSGI_APPLICATION = 'config.wsgi.application'
```

*In server/config/wsgi.py*
```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "drf_sample.settings")
    changes to
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings")
```

*In server/manage.py:*
```python
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "drf_sample.settings")
    changes to
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
```

We can test that our new links work by using `manage.py` from the terminal to run the project server.
```
$ python server/manage.py runserver

Performing system checks...

System check identified no issues (0 silenced).

You have unapplied migrations; your app may not work properly until they are applied.
Run 'python manage.py migrate' to apply them.

November 02, 2015 - 20:36:56
Django version 1.8, using settings 'config.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
```
Perfect!  Our project is now ready to support both server and client code.


## Looking Forward

Our project is in a good spot to begin development!  Look for to the next post soon, covering database model definition, model migration to the underlying SQL backend and model object creation through the python Django ORM.
