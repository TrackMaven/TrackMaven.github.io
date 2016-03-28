Title: Monthly Challenge: Functional Programming
Date: 2015-08-05
Category: Monthly Challenge
Tags: programming
Slug: monthly-challenge-functional-programming
Author: Josh Finnie
Avatar: josh-finnie

Our topic for this month's [Monthly Challenge meetup](http://www.meetup.com/TrackMaven-Monthly-Challenge/) is Functional Programming! In this post, we'll get you started with one of the many languages out there dedicated to functional programming: [Haskell](https://www.haskell.org/)! Here at TrackMaven, we write most of our code in Python and JavaScript, which are both capable of writing functional programming in their own right, but with the true spirit of our Monthly Challenges, I am going to write about a language that I am not super familiar with and see what we can do with it.

### What is Functional Programming

But first, what is functional programming and why are we dedicating an entire Monthly Challenge to the topic? Functional Programming is the practices of writing code using solely functions avoiding both changing state and mutable data. <sup>[[1](https://en.wikipedia.org/wiki/Functional_programming)]</sup> Having side-effect free functions being the building blocks of your code can ease the difficulty found in some complicated problems. However, using the functional programming paradigm is quite different from the standard paradigm of Object Orientated programming and hopefully this blog post will give you a nice primer for it.

Within the world of functional programming, there are a few "heavy-hitters" to choose from. As I said above, in this blog post we are going to focus on Haskell, but there are many more; here is a list of a few I recommend you checking out:

- [F#](http://fsharp.org/)
- [OCaml](https://ocaml.org/)
- [Erlang](http://www.erlang.org/)
- [Clojure](http://clojure.org/)
- [Scala](http://www.scala-lang.org/)

### First Functional Program

Let's jump right in and get our feet wet with Haskell! The first thing we want to do in make sure Haskell is installed on our machine. To do this, simply go to [this website](https://www.haskell.org/platform/) and download the Haskell Platform for your operating system. Once installed you should be able to run `ghci` and get into the interactive Haskell compiler called "Glasgow Haskell Compiler."

```bash
$ ghci
GHCi, version 7.10.1: http://www.haskell.org/ghc/  :? for help
Prelude>
```

Once in the interactive compiler, we can start to use Haskell. Using the built-in function `putStrLn`, we can print out "Hello World!" simply by running the following command:

```haskell
Prelude> putStrLn "Hello, world!"
Hello, world!
```

We have written your first Haskel program. Sure it wasn't that impressive, but I hope it portrayed the functional programming paradigm. `putStrLn` in a function that takes an argument of type "String". To see a function's [signature](https://wiki.haskell.org/Type_signature), just run the following command:

```haskell
Prelude> :t putStrLn  
putStrLn :: String -> IO ()
```

The signature of the function shows its "name" (`putStrLn`), its "argument(s) type" (`String`) and its "output type" (`IO ()`). Using this becomes helpful later on as you interact with and create custom functions. Next, let's get a little more in-depth (and away from "Hello World") and take a look at the factorial algorithm:

```haskell
Prelude> let fac n = if n == 0 then 1 else n * fac (n-1)
Prelude> fac 10
3628800
```

Here you can see we have defined a simple function called `fac` which will calculate the factorial of a given number. The awesome thing about this function is that we even recursively calls it to help with the calculation. Seeing the ease in which a factorial is calculated really starts to make you believe that the functional programming paradigm is something to look forward to.

### Functional Programming IRL

Now that we have a few examples under our belt, let's take a look at where you might have seen the functional programming paradigm before. If you are familiar with the python web development ecosystem you are probably familiar with the argument between these two programming paradigms. 

In [Django](https://www.djangoproject.com/), there are two main ways to go about programming a `view`, there are Class-Based `view`s and there are functional `view`s. Each of them has their benefits and drawbacks, but it does a great job at illustrating the differences between function programming and object oriented programming. When dealing with a individual viewpoint of a website, it is easy to thing of it as a singleton function:

```python
from django.http import HttpResponse
import datetime

def current_datetime(request):
    now = datetime.datetime.now()
    html = "<html><body>It is now {}.</body></html>".format(now)
    return HttpResponse(html)
```

In the above example, you have a function that explicitly deals with a single response. Its job is to accept a request and respond with an HTML template with the current time. Class-Based views within the Django ecosystem came along as the complexity of web applications grew. As endpoints had to deal with different request methods, you started to see a lot of duplication in your code:

```python
from django.http import HttpResponse

def my_view(request):
    if request.method == 'GET':
        # <view logic>
        return HttpResponse('result')
    if request.method == 'POST':
        # <view logic>
        return HttpResponse('result')
```

And class-based inheritance, something you cannot get in pure functional programming, you were allowed to simplify your code through inheritance to something that looked like this:

```python
from django.http import HttpResponse
from django.views.generic import View

class MyView(View):
    def get(self, request):
        # <view logic>
        return HttpResponse('result')
        
    def post(self, request):
        # <view logic>
        return HttpResponse('result')
```

Now, your logic is cleaner, but you are left with the programmatic black-box that is `View`. This is a class that was provided to you through the Django framework and is now starting to add a lot of weight to your application where a functional programming paradigm works just as well. And to this day, the debate on whether or not CBVs are the proper way to write views in Django carries on.

### More Haskell

Now let's have a little more fun with Haskell. We are going to write a simple command-line game where we are going to try and guess the number the computer is thinking of. To do this, let's create a file named `guess-the-number.hs` and copy in the following code:

```haskell
import System.Random  
import Control.Monad(when)  

isValidNumber n = do
    n > 0 && n < 10

testGuessedNumber a b = do
    if a == b
        then putStrLn "You're correct!"
        else putStrLn $ "Sorry, the correct answer was " ++ show a
  
main = do  
    gen <- getStdGen  
    let (randNumber, _) = randomR (1,10) gen :: (Int, StdGen)     
    putStr "Which number in the range from 1 to 10 am I thinking of? "  
    numberString <- getLine  
    when (not $ null numberString) $ do  
        let number = read numberString  
        if isValidNumber number
            then testGuessedNumber randNumber number
            else putStrLn $ "Please select a number between 1 and 10!"
        newStdGen  
        main
```

We can now run this program through our Haskell interpreter by running the following command `runhaskell guess_the_number.hs`. Doing so, we should be prompted to guess a number:

```bash
Which number in the range from 1 to 10 am I thinking of?
```

We put in some basic validation, so give it a go and see what happens!

```bash
$ runhaskell guess_the_number.hs
Which number in the range from 1 to 10 am I thinking of? 2
You're correct!
Which number in the range from 1 to 10 am I thinking of? 1
Sorry, the correct answer was 6
Which number in the range from 1 to 10 am I thinking of? 11
Please select a number between 1 and 10!
Which number in the range from 1 to 10 am I thinking of? -1
Please select a number between 1 and 10!
Which number in the range from 1 to 10 am I thinking of? a
guess_the_number.hs: Prelude.read: no parse
```

The validation does a pretty good job as long as we put in numbers, but we crashed the application when we inputed a letter. There are obvious improvements we could make to our validation, but I am going to leave that up to you.

### Even More Haskell

I wanted to make the above program a little more "haskellonic" (like pythonic, but for Haskell...) So I took a lot of the functions we created above, gave them proper signatures and added a little recursion!

Below is the finished program:

```haskell
import System.Random  

randomNumber = 4 -- chosen by fair dice roll.
                 -- guaranteed to be random.

isValidNumber :: Int -> Bool
isValidNumber n
    | n > 0 && n < 10 = True
    | otherwise       = False

testGuessedNumber :: Int -> Int -> Bool
testGuessedNumber a b
    | a == b    = True
    | otherwise = False

getInt :: IO Int
getInt = do
    num <- getLine
    return $ (read num :: Int)

main :: IO ()
main = do  
    putStr "Which number in the range from 1 to 10 am I thinking of? "
    number <- getInt 
    if isValidNumber number
        then run randomNumber number
        else putStrLn "please select a number between 1 and 10."

run :: Int -> Int -> IO()
run r n
    | outcome == True = do
        putStrLn "You Win!"
    | outcome == False = do
        putStrLn "You guessed incorrectly, please try again."
        number <- getInt
        run r number
    where outcome = testGuessedNumber r n
```

As one can see, I had some issues with randomness in Haskell (among other things...), but above it at least a much more well-rounded example of Haskell code where you can start to see some of the benefits.

### Conclusion

I have to say that I was impressed with the syntax and ease of (most parts of) Haskell, but I have to admit I am not jumping ship anytime soon. This could be because I didn't give it the true time it deserved, or it could be because I am so spoiled with Python. What are your thoughts about Functional Programming? 

Please [let us know](mailto:engineroom@trackmaven.com) if you have tried out anything interesting using functional programming - bonus points if you include an open-source repo. You can see what we did for the TrackMaven Monthly Challenge here: [challenge.hackpad.com](http://challenge.hackpad.com)
