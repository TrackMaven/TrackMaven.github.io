Title: Mocking Mistakes
Date: 2015-12-01
Category: Testing
Tags: testing, mock
Slug: mocking-mistakes
Author: Jon Evans
Avatar: jonathan-evans

I've discussed the value of using Python's `mock` library for testing in a couple of previous articles [Making a Mockery of Python](http://engineroom.trackmaven.com/blog/making-a-mockery-of-python/) and [Real Life Mocking](http://engineroom.trackmaven.com/blog/real-life-mocking/). Recently, however, a [kind commenter](http://engineroom.trackmaven.com/blog/real-life-mocking/#comment-2310097361) brought to my attention an insidious error in my example code. Having looked into this sneaky mistake, I wanted to briefly discuss it - hopefully I can prevent other developers encountering similar pitfalls!

## Mock mocks everything

The best way to explain the mistake is to look closely at an intended property of mock objects: whatever method or property we request from them, they will happily oblige us, regardless of whether that method/property exists on the object we are mocking. If we have explicitly set a `return_value` for a method, or set a property, we will get back what we set. If we haven't, however, we'll just get a `mock.Mock` object back:

```python
>>> import mock
>>> m = mock.Mock()
>>> m.foo
<Mock name='mock.foo' id='139896826878440'>
>>> type(m.foo)
<class 'mock.Mock'>
>>> m.bar()
<Mock name='mock.bar()' id='139896827174864'>
>>> type(m.bar())
<class 'mock.Mock'>
```

The reason this is useful is because when we are replacing a complex object with a mock object, we don't have to define all of the methods and properties on it - only the ones we care about in our test. The rest of the calls to the object will just respond silently with new mock objects.

## Mocking the unexpected

The problem occurs when we mix in the fact that mock objects also have their own, built-in methods used for verification: for example, the `assert_called_once_with` method is used to check that a mock was called exactly once with a specific set of arguments. This is all well and good, until we accidentally use a verification method that doesn't actually exist...

`assert_called_once_with` is a special verification method, so naturally `assert_called_once` is a verification method too, right? Wrong. `assert_called_once` is nowhere to be found in the [mock documentation](https://docs.python.org/3/library/unittest.mock.html). However, if we call it in our test, when we're expecting a mocked method to be called once, the test will pass. What we think is happening is that the method was called once, and everything is fine. What is actually happening is that the method could have been called 100 times, or not called at all. The test is passing because `assert_called_once()` silently returns a mock object, just like `m.bar()` in our example above. It's not actually checking anything.

This mistake has completely blindsided me in the past. In fact, looking over some of my old code, I found several examples of having used `assert_called_once`, as well as the equally innocuous-looking `assert_not_called` - another non-existent verification method.

## Mitigating mistaken mocks

Having learned about this mistake, how do we mitigate it? Fortunately, it's easy to replace `mock.assert_called_once()` with `assert mock.call_count == 1` - a statement that will only return true if the mock has actually been called once. Similarly, `mock.assert_not_called()` can be replaced with `assert mock.call_count == 0`. This solution was highlighted in [this post](http://engineeringblog.yelp.com/2015/02/assert_called_once-threat-or-menace.html) on the Yelp engineering blog. Since learning about it, I've started incorporating this style of assertion into all cases where I want to check how often something was called, but don't care about what arguments it was called with.

An alternative is to use the [`autospec` property](https://docs.python.org/3/library/unittest.mock.html#autospeccing) of the mock object. From the `mock` documentation:

> Auto-speccing creates mock objects that have the same attributes and methods as the objects they are replacing, and any functions and methods (including constructors) have the same call signature as the real object. This ensures that your mocks will fail in the same way as your production code if they are used incorrectly.

When we use the `autospec=True` argument in our `@mock.patch` decorator, our mock object will only exhibit the methods that actually exist on the original object we are replacing. Actual methods and properties specific to mock objects, like `assert_called_once_with` and `call_count`, are still accessible as well. However, methods that don't exist natively on the `mock.Mock` object *or* on the object being replaced will throw errors if they are called. Let's look at an example in a test:

```python
class ClientTestCase(unittest.TestCase)
    @mock.patch(self, 'client.MyAPIClient._create_headers', autospec=True)
    def test_client_get(mock_create_headers):

        response = client.MyAPIClient.get(url="http://engineroom.trackmaven.com/")

        mock_create_headers.assert_called_once()
```

This means that `assert_called_once` and `assert_not_called` are exposed as the deceptive fake methods that they were all along. The test above will fail as follows:

```
$ python tests.py
...E
======================================================================
ERROR: test_client_get (__main__.ClientTestCase)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/jonathan/.virtualenvs/blog_posts/local/lib/python2.7/site-packages/mock.py", line 1201, in patched
    return func(*args, **keywargs)
  File "tests.py", line 47, in test_client_get
    mock_create_handlers.assert_called_once()
  File "/home/jonathan/.virtualenvs/blog_posts/local/lib/python2.7/site-packages/mock.py", line 658, in __getattr__
    raise AttributeError("Mock object has no attribute %r" % name)
AttributeError: Mock object has no attribute 'assert_called_once'

----------------------------------------------------------------------
Ran 4 tests in 0.004s

FAILED (errors=1)
```

Autospeccing is useful for more things than preventing cheeky errors, so definitely take a look at it.

***

Have you been bitten by non-existent mock methods? Let me know in the comments!
