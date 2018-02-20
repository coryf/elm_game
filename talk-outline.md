# Using Elm and SVG to Build a Game

After going through a quick introduction into Elm, we will explore how to use it
to create a simple game.


## Elm intro

* Purely Function, transpiles (using haskell) to javascript and runs in the browser
* No runtime exceptions! (strict typing and null safety)
http://elm-lang.org/docs/syntax

* List
    List insert `item :: list`
    ```
    [1,2,3,4]
    1 :: [2,3,4]
    1 :: 2 :: 3 :: 4 :: []
    ```
* Tuples
* Records
* Currying-based functional languages (similar to Haskell)
    * Tuple calling vs Currying
```
add : (Number, Number) -> Number
add (a, b) = a + b

add (1, 2) 
  -- 3

add : Number -> Number -> Number
add a b = a + b

add 1 2
  -- 3

add (add 1 2) (add 3 4)
  -- 10

add : Number -> Number -> Number
add : Number -> (Number -> Number)
add a b = a + b

addOne : Number -> Number
addOne = add 1

addOne 5
  -- 6
```
* Pipelining
```
    2 |> add 1
    add 1 (2)
    add 1 2

    2
      |> add 1
      |> add 3

    add 3 (add 1 (2))
```

## Setting up the Game
* animationFrame - the game "loop"

## Physics

