Title: Real Life Mocking
Date: 2015-02-24
Category: Testing
Tags: testing, mock
Slug: real-life-mocking
Author: Jon Evans
Avatar: jonathan-evans


In a [previous post](http://engineroom.trackmaven.com/blog/making-a-mockery-of-python/) we discussed a basic use case for Python's fantastic `mock` library, showing how mock objects are useful for isolating components of an application and creating clean unit tests. By testing against the fake interface provided by a mock object, we can check how our functions are called, provide idealised outputs, and make sure that our unit tests are testing what we think they're testing.

That said, it's unlikely that in real life, the height of complexity of our unit tests will be checking if two numbers multiply correctly. This post will cover some ways that we use `mock` in our test suite at TrackMaven, examining a common case where `mock` really shines by replacing a slow, complex, or variable component - the HTTP request.

## What are we testing?

Building a web application that gathers data from an external source invariably involves interfacing with third-party APIs. Fortunately, making HTTP requests is a piece of cake in Python thanks to the [requests](http://docs.python-requests.org/en/latest/) library. However, when the time comes to test functionality that talks to an external service, the last thing we want is to actually talk to it. We care about testing how *our* code handles different, specific responses. Tying these tests to real requests means that we have no control over what type of response is returned: a test of code that handles a 200 OK response will not pass if the API endpoint is down, changes its structure, or returns a different response. While it may be important for us to know the state of an API, it is outside the scope of testing our own code's handling of responses.

For this reason, we can use `mock` to replace the result of an API call. There are many ways to do this, so let's look at an example:

```python
# client.py
import requests

class MyAPIClient(object):
    """A simple API client for querying corgi data"""

    base_url = 'http://api.corgidata.com'
    version = 'v1'

    def _make_uri(self, resource):
        """
        Construct the URL for a resource based on the API class's parameters
        """
        return '/'.join([self.base_uri, self.version, resource])

    def _get(self, url):
        """Make a GET request to an endpoint defined by 'url'"""

        response = requests.get(url=url)
        return response.json()

    def get_breed_info(self, breed):
        """Return information about a specific breed of corgi"""
        resource = '/'.join(['breeds', breed])
        url = self._make_url(resource=resource)
        response = self._get(url=url)
        return response
```

The above is a simple API client class for querying an (unfortuately fictional) API of corgi data. We are interested in testing the flow of our `_get` function to make sure that it:

- Calls the correct URL
- Attempts to deserialize the response JSON into Python

Currently our function is pretty simple. We could test it by just pointing it at the URL, calling it and checking that the response looks like we expect. However, this will be slow, and put our test at the mercy of a fickle third-party service. Instead, we will use `mock` to patch `requests.get` and replace it with our own, fake response object.

N.B. if you are following along at home, you want a directory structure like this:
```bash
.
├── client.py
├── __init__.py
└── tests.py

```

## Testing a successful call

Here is the contents of our `tests.py` file:

```python
# tests.py
import mock
import unittest

from client import MyAPIClient


class ClientTestCase(unittest.TestCase):

    def setUp(self):

        self.client = MyAPIClient()

    @mock.patch('client.requests.get')
    def test_get_ok(self, mock_get):
        """
        Test getting a 200 OK response from the _get method of MyAPIClient.
        """
        # Construct our mock response object, giving it relevant expected
        # behaviours
        mock_response = mock.Mock()
        expected_dict = {
            "breeds": [
                "pembroke",
                "cardigan",
            ]
        }
        mock_response.json.return_value = expected_dict

        # Assign our mock response as the result of our patched function
        mock_get.return_value = mock_response

        url = 'http://api.corgidata.com/breeds/'
        response_dict = self.client._get(url=url)

        # Check that our function made the expected internal calls
        mock_get.assert_called_once_with(url=url)
        self.assertEqual(1, mock_response.json.call_count)

        # If we want, we can check the contents of the response
        self.assertEqual(response_dict, expected_dict)

if __name__ == "__main__":
    unittest.main()
```

What is going on in this test?

First of all, we see the hopefully familiar `mock.patch` decorator - however, the argument to the decorator looks slightly different to the example in the [previous post](http://engineroom.trackmaven.com/blog/making-a-mockery-of-python/). This is because we are patching a function in a different file from the test case: the `client.requests.get` represents the path to the method we want to replace - in this case in `client.py`. But hang on! `requests.get` is defined in a third party package, not in our `client` module! This is true, but the `requests` module is being imported into `client.py` and called from that location. We always patch our functions, classes and methods in the place that they are *used*, rather than where they are defined. This can be a confusing distinction, but it is actually fairly well explained in the [mock documentation](https://docs.python.org/3/library/unittest.mock.html#where-to-patch).

Once we get inside our test, we have to set up our fake response object. To do this, we use mock in a different way: as an object. `mock.Mock()` gives us an object, similar to that dropped in by the `patch` decorator, to which we can attach arbitrary methods and variables. In our HTTP test, we use this mock object to recreate the requisite behaviors we want from our idealised response. Unlike making a real HTTP call, we now have complete control of the structure and behavior of the response, which is perfect for testing the logic of our `_get` method.

In order to make sure that it's working properly, we need to make sure that the mock response from our patched `requests.get` has a `.json` method. The following lines let us define an ideal response, and assign it as the return value of our mock response's `json` method:
```python
expected_dict = {
    "breeds": [
        "pembroke",
        "cardigan",
    ]
}
mock_response.json.return_value = expected_dict
```

This can be extremely useful if we need to define a deserialized response that looks like real data, for example if we want to check how it is manipulated later in the function.

After calling the `_get` method in our test, we check that it called the `requests.get` method, as well as making sure it called our `.json` method on our mock response.

```python
mock_get.assert_called_once_with(url=url)
self.assertEqual(1, mock_response.json.call_count)
```
Notice how we can make sure that any mock methods are called with the correct arguments, in this case making sure we requested the correct `url`.

The final piece of the puzzle is to check that the result of `_get` is the same as our dummy deserialized data:

```python
self.assertEqual(response_dict, expected_dict)
```

Since our `_get` method doesn't modify the data in any way, this is currently a guaranteed result. However, it is still useful as a regression test. If we change the method in any way, we want to make sure that we still end up with our deserialized data being passed out. Checking outputs gives us the confidence to change the method, knowing that our test will tell us if we make a breaking change.

## Testing an exception

This seems like an awful lot of time and effort to test a two-line function. Our test is considerably longer than our `_get` method - what's the point of that?

The value of testing code in this way is that it allows us to easily iterate on both the code, as well as the tests, while being confident that our code still works. As soon as our code gets more complicated, we can make sure that it is still working in a way that we expect, and it's easy to specify new conditions that we want our test to meet.

Let's illustrate this with an example. What if we want to add some error handling to our `_get` method, to make sure that we can recover from an HTTP error like a 404 or a 500? Here's our new, expanded method:

```python
def _get(self, url, retries=3):
    """Make a GET request to an endpoint defined by 'url'"""
    response = requests.get(url=url)
    try:
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        self._handle_http_error(e)
```

We can also define a HTTP error handler method on `MyAPIClient`. For the purposes of this demonstration, it doesn't matter what this does since we will be mocking it out - in practice, this could raise a custom exception or perform cleanup logic:

```python
def _handle_http_error(self, e):
    """Handle a HTTP error"""
    pass
```

How can we test that this new error handling works? First, let's rerun our success test and make sure that our changes haven't broken successful HTTP request handling. Once we've confirmed that this works, we can write a second test to prove that errors are handled correctly:

```python
import requests

class CustomHTTPException(Exception):
    pass


class ClientTestCase(unittest.TestCase):

...

    @mock.patch('client.MyAPIClient._handle_http_error')
    @mock.patch('client.requests.get')
    def test_get_http_error(self, mock_get, mock_http_error_handler):
        """
        Test getting a HTTP error in the _get method of MyAPIClient.
        """
        # Construct our mock response object, giving it relevant expected
        # behaviours
        mock_response = mock.Mock()
        http_error = requests.exceptions.HTTPError()
        mock_response.raise_for_status.side_effect = http_error

        # Assign our mock response as the result of our patched function
        mock_get.return_value = mock_response

        # Make our patched error handler raise a custom exception
        mock_http_error_handler.side_effect = CustomHTTPException()

        url = 'http://api.corgidata.com/breeds/'
        with self.assertRaises(CustomHTTPException):
            self.client._get(url=url)

        # Check that our function made the expected internal calls
        mock_get.assert_called_once_with(url=url)
        self.assertEqual(1, mock_response.raise_for_status.call_count)

        # Make sure we did not attempt to deserialize the response
        self.assertEqual(0, mock_response.json.call_count)

        # Make sure our HTTP error handler is called
        mock_http_error_handler.assert_called_once_with(http_error)

```

Our second test looks a lot like the test for a successful call. We are still making a mock response and giving it behaviours, and then making sure our method calls the correct internal functions. However, this test introduces a couple of new mocking tactics. Firstly, we are stacking `mock.patch` decorators:

```python
@mock.patch('client.MyAPIClient._handle_http_error')
@mock.patch('client.requests.get')
def test_get_http_error(self, mock_get, mock_http_error_handler):
```

Thanks to the power of decorators, we can mock an arbitrary number of functions with the `patch` method. In this case, we want to make sure that our client's `_handle_http_error` is called if an error is caught, as well as continuing to mock `requests.get`. We can just stack another decorator above our original one, and add a new argument to our test - the second mocked function. It is pretty crucial to note the **order** of the decorators and arguments to the test. The **top-most** mocked function corresponds to the **right-most** test argument. When mocking multiple functions, make sure that the decoratos and arguments are correctly lined up, or you might see some confusing and unexpected behaviour!

Secondly, let's take a closer look at the mock response's `raise_for_status` definition:

```python
http_error = requests.exceptions.HTTPError()
mock_response.raise_for_status.side_effect = http_error
```

We are no longer using `return_value`; instead, the method has a `side_effect`. `side_effect` is a very cool mocking trick that allows us to assign an exception to a method - when the method is called, the exception will be raised. In our test, this gives us the power to enter the `except` case of our `_get` method, and make sure that our handling of `HTTPError` is correct. `side_effect` has other powers, which we will take a look at in our third and final example.

Finally, we are making our patched `_handle_http_error` function throw a custom exception as its side effect. We can check that this exception was raised using a context manager:

```python
with self.assertRaises(CustomHTTPException):
    self.client._get(url=url)
```

This makes sure that the `_get` function exits with our custom exception when we introduce an `HTTPError`. Not only does this provide additional checking that our mock handler was called: it also allows us to make sure that further changes to the function won't break the error handling effects we expect.


## Testing a loop

Our `_get` method is looking more robust to exceptions, and we've tested it for both successful and erroneous HTTP responses. However, connections are tricky beasts - they could disappear temporarily due to the vagaries of the internets, or take a very long time to return a response due to server or network slowness. We want our `_get` method to deal with these facts, and retry a call if it fails with a connection error or timeout. Here's the final version of the method:

```python
def _get(self, url, retries=3):
    """Make a GET request to an endpoint defined by 'url'"""

    while retries > 0:
        try:
            response = requests.get(url=url)
            try:
                response.raise_for_status()
                return response.json()
            except requests.exceptions.HTTPError as e:
                self._handle_http_error(e)
        except (requests.exceptions.ConnectionError,
                requests.exceptions.Timeout) as e:
            retries -= 1
            if not retries:
                self._handle_connection_error(e)
```

And let's not forget to add a `_handle_connection_error` method to `MyAPIClient`, to deal with the situation where we've used up all of our retries. Once again, this will just be a stub for the purposes of this example:

```python
def _handle_connection_error(self, e):
    """Handle a persistent connection error or timeout"""
    pass
```

Now we're going to need to test to make sure our `_get` method handles `ConnectionError` or `Timeout` correctly. Our first two tests should still pass to cover the success and `HTTPError` cases. Can't we just add a third test that throws one of the two errors we are trying to handle? Unfortunately, no we can't. There is more than one new logical pathway specified by our retry loop:

- A `ConnectionError` or `Timeout` is raised 3 times and then `_handle_connection_error` is called.
- A `ConnectionError` or `Timeout` is raised 1 or 2 times and then a request is successful.
- A `ConnectionError` or `Timeout` is raised 1 or 2 times and then a request returns a `HTTPError`.

All of these imply us needing our mock `requests.get` to be called multiple times in a test, and sometimes to return or raise different things! What madness is this?!

First let's consider the test for a persistent connection failure:

```python
...
class CustomConnException(Exception):
    pass


class ClientTestCase(unittest.TestCase):

...

@mock.patch('client.MyAPIClient._handle_connection_error')
@mock.patch('client.requests.get')
def test_get_connection_error(self, mock_get, mock_conn_error_handler):
    """
    Test getting a persistent connection error in the _get method of
    MyAPIClient.
    """
    # Make our patched `requests.get` raise a connection error
    conn_error = requests.exceptions.ConnectionError()
    mock_get.side_effect = conn_error

    # Make our patched error handler raise a custom exception
    mock_conn_error_handler.side_effect = CustomConnException()

    url = 'http://api.corgidata.com/breeds/'
    with self.assertRaises(CustomConnException):
        self.client._get(url=url)

    # Check that our function made the expected internal calls
    expected_calls = [mock.call(url=url)] * 3
    self.assertEqual(expected_calls, mock_get.call_args_list)

    # Make sure our connection error handler is called
    mock_conn_error_handler.assert_called_once_with(conn_error)
```

We've now made our patched `requests.get` raise a `ConnectionError` every time it is called. In this version of the test, we want to end up by calling our error handler **after** having called `requests.get` not once, but three times. How can we check that the patched function was called the correct number of times, with the correct arguments each time? We need to use mock's `call` object. This allows us to create an arbitary representation of a call to a mocked function. If we make a list of these `call` objects, we can compare the list to the `call_args_list` property of our patched function to see if it was called how we expected, in the order we expected.

```python
expected_calls = [mock.call(url=url)] * 3
self.assertEqual(expected_calls, mock_get.call_args_list)
```

While in this case we are only checking three of the same call, in practice we could check any combination of calls with different arguments.

Now we're on the home stretch. We just need to cover the case of a `ConnectionError` occurring, followed by a successful call. This means we're going to have to manipulate our patched `requests.get` into first raising an error, and then returning a mock result when called again.

```python
    @mock.patch('client.requests.get')
    def test_get_connection_error_then_success(self, mock_get):
        """
        Test getting a connection error, then a successful response,
        in the _get method of MyAPIClient.
        """
        # Construct our mock response object for the success case
        mock_response = mock.Mock()
        expected_dict = {
            "breeds": [
                "pembroke",
                "cardigan",
            ]
        }
        mock_response.json.return_value = expected_dict

        # Make an instance of ConnectionError for our failure case
        conn_error = requests.exceptions.ConnectionError()

        # Give our patched get a list of behaviours to display
        mock_get.side_effect = [conn_error, conn_error, mock_response]

        url = 'http://api.corgidata.com/breeds/'
        response_dict = self.client._get(url=url)

        # Check that our function made the expected internal calls
        expected_calls = [mock.call(url=url)] * 3
        self.assertEqual(expected_calls, mock_get.call_args_list)
        self.assertEqual(1, mock_response.json.call_count)

        # Check the result
        self.assertEqual(response_dict, expected_dict)

```

Here we've combined the mock behaviours from our success example and our connection error example, and used `side_effect` to get the patched `requests.get` to exhibit different behaviours on consecutive calls. On the first two calls to the function in the test, it will raise a `ConnectionError`. On the final call, it will return a good response.

```python
mock_get.side_effect = [conn_error, conn_error, mock_response]
```

Wow. Now we have a test suite that covers successful responses, intermittent connections, and HTTP error responses, without having to make a single real HTTP call. These tests will **always** behave the same, and should allow us to make whatever changes we want to our `_get` method while being sure that the core functionality stays solid. If you want to practice what we've learned, try defining the final test case: a `ConnectionError` followed by a `HTTPError`.

## Wait, what did we test?

We've covered a whole load of things in this post, using a constructed example to illustrate:

- `mock.Mock()` as an object
- stacking `mock.patch` decorators
- using `side_effect` to raise an exception from a patched function
- using `mock.call()` to test calling a function multiple times
- using `side_effect` (again) to return different behaviours from the same function when it is called multiple times

Phew! That's a lot to take in. In real life, you may not want to unit test each of your functions with this level of rigour. However, in some cases, you might. Imagine that `MyAPIClient` is not just for looking up corgi data. Instead, it's an abstract class that powers all of your requests to many different APIs. With a comprehensive test suite of its core behaviours, we can be extremely confident that anything build on top of it will be stable and fail gracefully in a variety of failure modes. All this, thanks to the power and flexibility of the mock library! It's no wonder they included it in Python 3!

***

How do you use mock to make awesome unit tests? Did I miss a particularly powerful feature you'd like me to talk about? Just want to make 'mock' puns? Visit the comments section!

