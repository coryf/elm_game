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
- Subscriptions
- Update
- View

---

### Main function

Entry point for the Elm program. Sets up the inital model state, and sets the
update, subscription, and view functions.

@fa[arrow-down]

+++

```elm
main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
```

---

### Model

Sets up the type of the model and initial state.

@fa[arrow-down]

+++

```elm
type alias Ball =
    { position : Vec2
    , velocity : Vec2
    , acceleration : Vec2
    , restitution : Float
    , radius : Float
    }

type alias Paddle =
    { position : Vec2, velocity : Vec2, size : Vec2 }

type alias Model =
    { ball : Ball, paddle : Paddle, score : Int, gameOver : Bool }

initModel : Model
initModel =
    { ball =
        { position = Vec2 0 0
        , velocity = Vec2 400 0
        , acceleration = Vec2 0 0
        , restitution = -0.9
        , radius = 10
        }
    , paddle =
        { position = Vec2 400 900, velocity = Vec2 0 0, size = Vec2 200 10 }
    , score = 0
    , gameOver = False
    }

init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )
```

@[1-13](Model Type)
@[15-32](Model Initial State)

---

### Subscribe

Tells Elm which global messages you want to listen for.

@fa[arrow-down]

+++

```elm
type Msg
    = KeyDownMsg Keyboard.KeyCode
    | KeyUpMsg Keyboard.KeyCode
    | FrameDiffMsg Time

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyDownMsg
        , Keyboard.ups KeyUpMsg
        , AnimationFrame.diffs FrameDiffMsg
        ]
```
@[1-4](Msg Type)
@[6-12](Subscriptions Function)

---

### Update

Called when a message is received and returns the next version of the model.

@fa[arrow-down]

+++

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyUpMsg keyCode ->
            ( handleKeyUp (Char.fromCode keyCode) model, Cmd.none )

        KeyDownMsg keyCode ->
            ( handleKeyDown (Char.fromCode keyCode) model, Cmd.none )

        FrameDiffMsg timeDiff ->
            ( updateFrame (1 / 60) model, Cmd.none )
```


Note:
We define all possible types of messages that we will handle. In the update
function, we receive a message and the current model state, and we return
the next model state based on the action taken as a result of the message.

---

### View

- HTML building functions
- Virtual DOM rendering
- SVG functions

@fa[arrow-down]

+++

```elm
view : Model -> Html Msg
view model =
    div
        [ class "wrapper" ]
        [ h1
            [ style
                [ ( "color", "red" )
                , ( "fontFamily", "Comic Sans MS" )
                ]
            ]
            [ text "Hello World" ]
        ]
```

Note:
The view function take a model and returns Html Msg type. The returned HTML
can send messages based on browser events (onClick, onChange), so we need to
pass-through the Msg type as a component of the Html type thats returned.

+++

```elm
view : Model -> Html Msg
view model =
    svg
        [ width "100%", height "100%", viewBox viewBoxString, overflow "hidden" ]
        ([ background
         , titleLabel "A Game"
         , scoreLabel (toString model.score)
         , ballView model.ball
         , paddleView model.paddle
         , gameOverLabel model.gameOver
         ]
             ++ (vectors model.ball)
        )
```
@[8](ballView nested SVG component)

+++

```elm
ballView : Ball -> Svg msg
ballView { position, radius } =
    let
        { x, y } =
            position
    in
        circle
            [ fill "blue", cx (toString x), cy (toString y), r (toString radius) ]
            []
```

---

### Setting up the Game

animationFrame

@fa[arrow-down]

Subscription

@fa[arrow-down]

Update Model

@fa[arrow-down]

View

---

## Physics

---

### 2D Vector

- Direction and magnitude expressed as x,y components
- Line is two Vectors for each endpoint

@fa[arrow-down]

+++

### Types

```elm
type alias Vec2 = { x : Float , y : Float }
type alias Line2 = ( Vec2, Vec2 ) 
```

+++

### Vector Math


```elm
scaleVec2 : Float -> Vec2 -> Vec2
scaleVec2 scalar v = { x = v.x * scalar, y = v.y * scalar }

addVec2 : Vec2 -> Vec2 -> Vec2
addVec2 v1 v2 = { x = v1.x + v2.x, y = v1.y + v2.y }

multVec2 : Vec2 -> Vec2 -> Vec2
multVec2 v1 v2 = { x = v1.x * v2.x, y = v1.y * v2.y }
```


---

### Gravity

A constant downward acceleration. 9.81 m/s^2 near the Earth's surface.

---

### Position Velocity Acceleration

- position = x,y (magnitude and direction)
- velocity = meters per second
- acceleration = meters per second per second

Note:
Show game with vectors draw. Velocity is the rate and direction of change in
position. Acceleration is the rate and direction of change in velocity.

@fa[arrow-down]

+++

```elm
updateFrame : Float -> Model -> Model
updateFrame t model =
    let
        prevPosition =
            model.ball.position

        updatedModel =
            { model
                | ball = model.ball |> updateBallPosition t
                , paddle = model.paddle |> updatePaddlePosition t
            }
    in
        if model.gameOver then
            model
        else
            updatedModel
                |> collideWalls prevPosition
                |> collidePaddle prevPosition
```
@[9](Update the ball position)

+++

```elm
updateBallPosition : Time -> Ball -> Ball
updateBallPosition t object =
    { object
        | position = addVec2 object.position (scaleVec2 t object.velocity)
        , velocity = addVec2 object.velocity (scaleVec2 t object.acceleration)
        , acceleration = Vec2 0 (9.8 * 100)
    }
```

Note:
Add velocity to position. Add acceleration to velocity. Set acceleration to
gravity.

---

### Faking Bounce

- F = ma
- Reflection of Velocity
- Restitution (Bounceability)

Note:
Faking bounce as a reflection of velocity. Velocity doesn't change 
instantaneously in the real world. Instead, the ground applies a force against
the ball (and the ball atoms against other ball atoms) to create an upward
acceleration. The ball also applies a force against the ground (earth), but that
force can be ignore for most practical purposes. There is also heat lost in the
process of bouncing. All of these factors are being faked by a single number
called restitution that reflects and dampens the velocity.

---

### Collision Detection

- Wall: Bounding x and y checks
- Paddle: Line segment intersection
- Scoring: Collide with top of paddle
- Game over: Collide with bottom of wall

---

## Game Over

- https://github.com/coryf/elm_game
- https://gitpitch.com/coryf/elm_game
- https://coryf.github.io/elm_game/
