# Elm Game Dev
## with SVG

### Presented by Cory Fabre

---

## Elm intro

- Purely Functional
- Transpiles to javascript and runs in the browser
- No runtime exceptions!

Note:
Purely functional - Functions are pure and always return the same output given
the same input. No hidden state.

No runtime exception: strict typing and null safety

http://elm-lang.org/docs/syntax

---

### Comments

```elm
-- a single line comment

{- a multiline comment
   {- can be nested -}
-}
```

---

### Literals

```elm
-- Boolean
True  : Bool
False : Bool

42    : number  -- Int or Float depending on usage
3.14  : Float
'a'   : Char
"abc" : String

-- multi-line String
"""
This is useful for holding JSON or other
content that has "quotation marks".
"""
```

---

### List

```elm
["hello", "world"]

--- next three lists are equivalent
[1, 2, 3, 4]
1 :: [2, 3, 4]
1 :: 2 :: 3 :: 4 :: []
```

Note:
Order list of items of the same type. Insertion is at the head of the list.

---

### Tuples

```elm
(1.0, True, 'a')
("A", ("Nested", "Tuple"))

(1.0, True, 'a') : (Float, String, Char)
```

Note:
Tuples are like anonymous structures. They can hold a mixer of types. The type
of a tuple is defined by the type of its components.


---

### Records

```elm
point =                         -- create a record
  { x = 3, y = 4 }

point.x                         -- access field

{ point |                       -- update fields
    x = point.x + 1,
    y = point.y + 1
}

type alias Location =           -- type aliases for records
  { line : Int
  , column : Int
  }
```

---

### Patern Matching

```elm
point = {x: 10, y: 20}
{x, y} = point

dist {x,y} =
  sqrt (x^2 + y^2)
```

---

### Currying

```elm
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

@[1-5](Single tuple param, similar to many other languages)
@[7-11](Currying parameters, standard Elm style)
@[13-14](Nested function calling)
@[16-18](These function type signatures are equivalent)
@[20-24](Example of partial application)

Note:
Currying-based functional languages (similar to Haskell and ML)
Tuple calling vs Currying
No parentheses or commas in the function call.
Partial application of arguments returns a function.

---

### Let Expressions

```elm
let
  twentyFour =
    3 * 8

  sixteen =
    4 ^ 2
in
  twentyFour + sixteen
```


Note:
Let expression define scope constants


---

### Pipelining

```elm
-- (arg |> func) is the same as (func arg)

2 |> add 1
add 1 (2)
add 1 2

2 |> add 1
  |> add 3
add 3 (add 1 (2))
```

@[1](Pipe operator is an alias for function application)
@[3-5](Single function pipe)
@[7-9](Multiple function pipe)

Note:
Similar to Elixir syntax, but the argument is added to the end because of how
currying works. Can reduce parens and lead to better readability.

---

## Parts of an Elm Program

- Main function
- Model
- Update
- Subscriptions
- View

---

### Main function

Entry point for the Elm program. Sets up the inital model state, and sets the
update, subscription, and view functions.

@fa[arrow-down]

+++?code=Main.elm&lang=elm
@[17-24]

---

### Model

Sets up the type of the model and initial state.

@fa[arrow-down]

+++?code=Main.elm&lang=elm
@[114-135](Model Type)

+++?code=Main.elm&lang=elm
@[138-154](Model Initial State)

---

### Setting up the Game
* animationFrame - the game "loop"

### Physics
* 2D Vector
    * _Picture_ Direction and magnitude expressed as x,y components
    * used to describe position, velocity, and acceleration
    * Faking bounce, reflection of velocity instead of acceleration from force
* Vector Math

