Title: Making a Mockery of Python
Date: 2014-12-01
Category: Testing
Tags: testing, mock
Slug: making-a-mockery-of-python
Author: Jon Evans
Avatar: jonathan-evans


Today we will be talking about mocking. No, not the joke at someone else's expense kind. Mocking is a technique to temporarily replace **real** parts of our code with **fake**, simpler parts, so that we can check that the rest of the parts are working as we intend. Here we'll consider some simple use cases for mocking in Python tests, and try to show how this extremely useful technique can make us better at testing.

## Why do we mock?

When we carry out unit testing, our goal is to test a small section of code - for example a function or class method - in isolation. In other words, we should only be testing the code that is contained in said function. If we rely on calls to other pieces of code in our test, then we find ourselves in an unfortunate situation where changes to the nested code can break the test, despite the code of the function being tested remaining the same. This is best illustrated by example:

```python
# function.py
def add_and_multiply(x, y):

    addition = x + y
    multiple = multiply(x, y)

    return (addition, multiple)


def multiply(x, y):

    return x * y

# test.py
import unittest


class MyTestCase(unittest.TestCase):
    def test_add_and_multiply(self):

        x = 3
        y = 5

        addition, multiple = add_and_multiply(x, y)

        self.assertEqual(8, addition)
        self.assertEqual(15, multiple)

if __name__ == "__main__":
    unittest.main()
```

```
$ python test.py
.
----------------------------------------------------------------------
Ran 1 test in 0.001s

OK
```

In the simple case above, we have a function that adds and multiplies two numbers, and returns both the sum and the multiple. The `add_and_multiply` function calls a second function, `multiply` to perform the multiplication operation.

Suppose we decided that we wanted to dispense with 'traditional' mathematics, and redefine our multiply function to always add three to the numbers being multiplied.

Our new 'multiplication' function looks like this:

```python
def multiply(x, y):

    return x * y + 3
```

Now we encounter a problem. Our test code hasn't changed. The function we are supposedly testing hasn't changed. However, the `test_add_and_multiply` test will now fail:

```
$ python test.py
F
======================================================================
FAIL: test_add_and_multiply (__main__.MyTestCase)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "test.py", line 13, in test_add_and_multiply
    self.assertEqual(15, multiple)
AssertionError: 15 != 18

----------------------------------------------------------------------
Ran 1 test in 0.001s

FAILED (failures=1)
```

The issue here is that our original test was not a *true* unit test. Despite intending only to test our outer function, we are implicitly testing the inner function as well, since our desired result depends on its behaviour. This may seem like a pointless distinction in the simple case above, but in a situation where we are testing a complex piece of logic - for example, a Django view function that calls various different inner functions based on certain conditionals - it becomes more important to separate the testing of the view logic from the results of the function calls.

There are two ways to solve this problem. We either ignore it, call our unit test an integration test and move on, or we can turn to **mocking**. The disadvantage of the first course of action is that an integration test only tells us something is broken somewhere along the line of function calls - it makes it much harder to identify where the issue lies. This is not to say that integration tests aren't useful, because they are. However, unit tests and integration tests solve different problems, and should be used in tandem. So if we want to be good testers, we choose the alternative: the `mock` library.

## What is mock?

`mock` is a Python package so awesome, it was added to the standard library in Python 3. For those of us peasants still toiling in the UnicodeError-strewn fields of Python 2.x, you can install it through pip:

```bash
pip install mock==1.0.1
```

There are many different ways to use `mock`. We can use it to monkey-patch functions, create fake objects, or even as a context manager. All of these implementations serve one overall purpose - replacing parts of our code with replicas that we can use to a) gather information and b) return contrived responses.

`mock`'s [documentation](http://www.voidspace.org.uk/python/mock/) can be quite dense, and finding information on a particular use-case can be tricky. Here, we'll take a look at a common scenario - replacing a nested function to check its inputs and outputs.

## We will mock you

Let's rewrite our unit test, using the power of mock. Then we'll discuss what's happening, and why it is useful from the perspective of testing.

```python
# test.py
import mock
import unittest


class MyTestCase(unittest.TestCase):

    @mock.patch('multiply')
    def test_add_and_multiply(self, mock_multiply):

        x = 3
        y = 5

        mock_multiply.return_value = 15

        addition, multiple = add_and_multiply(x, y)

        mock_multiply.assert_called_once_with(3, 5)

        self.assertEqual(8, addition)
        self.assertEqual(15, multiple)

if __name__ == "__main__":
    unittest.main()
```

At this point, we can change the multiply function to do whatever we want - it could return the multiple plus three, return None, or return your [favourite line from Monty Python and the Holy Grail](https://www.youtube.com/watch?v=q-yxOFIkgxU&t=1m15s) - and our test above will still pass. This is because we are **mocking** the multiply function. In true unit test fashion, we don't care about what happens inside the multiply function; from the perspective of our `add_and_multiply` test, we only care that `multiply` was called with the right arguments. We assume (hopefully, correctly) that what is going on *inside* `multiply` is itself being tested by another unit test.


## What just happened?

The syntax used above may look confusing at first. Let's consider the relevant lines more closely:

```python
@mock.patch('multiply')
def test_add_and_multiply(self, mock_multiply):
```

We've used the `mock.patch` decorator to **replace** `multiply` with a mock object. We then insert this into our test by passing it as an argument, which we've called `mock_multiply`. Within the context of the test, any call to `multiply` will be redirected to our `mock_multiply` object.

Cries of terror - "How can we be replacing a function with an object!?" Don't worry! This is Python, so functions **are** objects. Normally, when we call `multiply()`, we are using the `__call__` method of the `multiply` function object. With our mock in place, however, our `multiply()` call instead calls the `__call__` method of our mock object.

```python
mock_multiply.return_value = 15
```

In order to get our mock function to return anything, we need to specify the `return_value` attribute. This tells our mock object what to give back when it is called.

```python
addition, multiple = add_and_multiply(x, y)

mock_multiply.assert_called_once_with(3, 5)
```

In the test, we then called our outer function, `add_and_multiply`. This will call our nested `multiply` function, and if we've mocked it correctly, the call will be received by our mock object instead. To check that this has happened, we can rely on a smart feature of mock objects - they store any arguments that they were called with. The `assert_called_once_with` method of the mock object is a nice shortcut to check, as the name suggests, if the object was called once with a specific set of arguments. If it was, we are happy and the test passes. If it wasn't, `assert_called_once_with` will let us know by raising an `AssertionError`.

## What have we achieved?

Well, quite a lot actually. Firstly, we have **isolated** the functionality of `add_and_multiply` from the functionality of `multiply` by mocking the nested function. This means that our unit test is only testing logic specifically inside `add_and_multiply`. Only changes to the code of `add_and_multiply` will affect the success or failure of the test.

Secondly, we can now control the outputs of our nested function to make sure our outer function handles different cases. For example, our `add_and_multiply` function might have conditional logic based on the result of `multiply`: say, we only want to return a value if the multiple is greater than 10. We could easily test that our logic works by generating contrived outputs from `multiply` to mimic the case where the multiple is less than 10, and the case where the multiple is greater. This feature of mock objects is great for testing control flow.


Finally, we can now make sure that our mocked function is being called the correct number of times, with the correct arguments. Since our mock object is sitting where our `multiply` function normally sits, we know that any calls made to it would normally go to `multiply`. When testing a complex function, it is extremely reassuring to make sure that each step is being called correctly.

***

The example given above only scratches the surface of what `mock` can do. In an upcoming post, we'll look at some more in-depth examples of using the library, as well as identifying some pitfalls to avoid. Meanwhile, questions are welcome in the comments, or on Twitter!