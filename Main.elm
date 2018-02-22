module Main exposing (main)

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import AnimationFrame
import Time exposing (Time)
import Keyboard
import Mouse
import Window
import Char


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


res =
    1000


margin =
    50



-- Vector Math


type alias Vec2 =
    { x : Float
    , y : Float
    }


type alias Line2 =
    ( Vec2, Vec2 )


scaleVec2 : Float -> Vec2 -> Vec2
scaleVec2 scalar v =
    { x = v.x * scalar, y = v.y * scalar }


addVec2 : Vec2 -> Vec2 -> Vec2
addVec2 v1 v2 =
    { x = v1.x + v2.x, y = v1.y + v2.y }


multVec2 : Vec2 -> Vec2 -> Vec2
multVec2 v1 v2 =
    { x = v1.x * v2.x, y = v1.y * v2.y }


type PointWinding
    = Colinear
    | Clockwise
    | Counterclockwise


segmentIntersects : Line2 -> Line2 -> Bool
segmentIntersects ( l1v1, l1v2 ) ( l2v1, l2v2 ) =
    let
        between p q r =
            let
                ( maxX, minX, maxY, minY ) =
                    ( Basics.max p.x r.x
                    , Basics.min p.x r.x
                    , Basics.max p.y r.y
                    , Basics.min p.y r.y
                    )
            in
                q.x <= maxX && q.x >= minX && q.y <= maxY && q.y >= minY

        winding p q r =
            let
                n =
                    (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
            in
                if n == 0 then
                    Colinear
                else if n > 0 then
                    Clockwise
                else
                    Counterclockwise

        ( w1, w2, w3, w4 ) =
            ( winding l1v1 l1v2 l2v1
            , winding l1v1 l1v2 l2v2
            , winding l2v1 l2v2 l1v1
            , winding l2v1 l2v2 l1v2
            )
    in
        (w1 /= w2 && w3 /= w4)
            || (w1 == Colinear && (between l1v1 l2v1 l1v2))
            || (w2 == Colinear && (between l1v1 l2v2 l1v2))
            || (w3 == Colinear && (between l2v1 l1v1 l2v2))
            || (w4 == Colinear && (between l2v1 l1v2 l2v2))



-- MODEL


type alias Ball =
    { position : Vec2
    , velocity : Vec2
    , acceleration : Vec2
    , restitution : Float
    , radius : Float
    }


type alias Paddle =
    { position : Vec2
    , velocity : Vec2
    , size : Vec2
    }


type alias Model =
    { ball : Ball
    , paddle : Paddle
    , score : Int
    , gameOver : Bool
    }


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
        { position = Vec2 400 900
        , velocity = Vec2 0 0
        , size = Vec2 200 10
        }
    , score = 0
    , gameOver = False
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- UPDATE


type Msg
    = KeyDownMsg Keyboard.KeyCode
    | KeyUpMsg Keyboard.KeyCode
    | FrameDiffMsg Time


gravity =
    9.8 * 100


applyGravity : Ball -> Ball
applyGravity object =
    { object | acceleration = Vec2 0 gravity }


updateBallPosition : Time -> Ball -> Ball
updateBallPosition t object =
    { object
        | position = addVec2 object.position (scaleVec2 t object.velocity)
        , velocity = addVec2 object.velocity (scaleVec2 t object.acceleration)
        , acceleration =
            object
                |> applyGravity
                |> .acceleration
    }


collideWalls : Vec2 -> Model -> Model
collideWalls prevPosition ({ ball } as model) =
    let
        radius =
            ball.radius

        { x, y } =
            ball.position

        ( movingLeft, movingUp ) =
            ( ball.velocity.x < 0, ball.velocity.y < 0 )

        ( hitLeft, hitRight, hitTop, hitBottom ) =
            ( x < radius, x > res - radius, y < radius, y > res - radius )

        bounceX =
            if (hitRight && not movingLeft) || (hitLeft && movingLeft) then
                ball.restitution
            else
                1

        bounceY =
            if (hitBottom && not movingUp) || (hitTop && movingUp) then
                ball.restitution
            else
                1
    in
        { model
            | ball =
                { ball
                    | velocity = multVec2 ball.velocity (Vec2 bounceX bounceY)
                }
            , gameOver = hitBottom
        }


collidePaddle : Vec2 -> Model -> Model
collidePaddle prevPosition ({ paddle, ball } as model) =
    let
        ballLine =
            ( prevPosition, ball.position )

        ( left, top ) =
            ( paddle.position.x, paddle.position.y - ball.radius )

        ( right, bottom ) =
            ( left + paddle.size.x, top + paddle.size.y + (ball.radius * 2) )

        topLine =
            ( Vec2 left top, Vec2 right top )

        bottomLine =
            ( Vec2 left bottom, Vec2 right bottom )

        hitTop =
            segmentIntersects ballLine topLine && ball.velocity.y > 0

        hitBottom =
            segmentIntersects ballLine bottomLine && ball.velocity.y < 0

        bounceY =
            hitTop || hitBottom

        updatedBall =
            if bounceY then
                { ball
                    | velocity = multVec2 ball.velocity (Vec2 1 ball.restitution)
                }
            else
                ball

        updatedScore =
            if hitTop then
                model.score + 1
            else
                model.score
    in
        { model | ball = updatedBall, score = updatedScore }


updatePaddlePosition : Time -> Paddle -> Paddle
updatePaddlePosition t paddle =
    { paddle
        | position = addVec2 paddle.position (scaleVec2 t paddle.velocity)
    }


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


movePaddle : Paddle -> Float -> Paddle
movePaddle paddle direction =
    { paddle | velocity = Vec2 (direction * 1000) 0 }


resetGame : Model -> Model
resetGame model =
    initModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ paddle } as model) =
    case msg of
        KeyUpMsg keyCode ->
            ( { model | paddle = movePaddle paddle 0 }, Cmd.none )

        KeyDownMsg keyCode ->
            let
                keyChar =
                    Char.fromCode keyCode
            in
                case keyChar of
                    'A' ->
                        -- Move Left
                        ( { model | paddle = movePaddle paddle -1 }, Cmd.none )

                    'D' ->
                        -- Move Right
                        ( { model | paddle = movePaddle paddle 1 }, Cmd.none )

                    'R' ->
                        ( resetGame model, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

        FrameDiffMsg timeDiff ->
            let
                -- Fake time for now, but look into looping 1/60 (framerate)
                -- chunks of (Time.inSeconds timeDiff)
                t =
                    1 / 60
            in
                ( updateFrame t model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyDownMsg
        , Keyboard.ups KeyUpMsg
        , AnimationFrame.diffs FrameDiffMsg
        ]



-- VIEW


background : Svg msg
background =
    rect
        [ fill "#ccc"
        , x "0"
        , y "0"
        , width (toString res)
        , height (toString res)
        , rx "10"
        , ry "10"
        ]
        []


labelCustom : List (Svg.Attribute msg) -> Float -> Float -> String -> Svg msg
labelCustom attrs x_ y_ string =
    text_
        ([ x (toString x_)
         , y (toString y_)
         , fontFamily "Comic Sans MS"
         , fontSize "32"
         ]
            ++ attrs
        )
        [ text string ]


label : Float -> Float -> String -> Svg msg
label =
    labelCustom []


scoreLabel : String -> Svg msg
scoreLabel =
    labelCustom [ textAnchor "end" ] (res - margin) margin


titleLabel : String -> Svg msg
titleLabel =
    label margin margin


ballView : Ball -> Svg msg
ballView { position, radius } =
    let
        { x, y } =
            position
    in
        circle
            [ fill "blue", cx (toString x), cy (toString y), r (toString radius) ]
            []


paddleView : Paddle -> Svg msg
paddleView { position, size } =
    let
        ( x_, y_ ) =
            ( toString position.x, toString position.y )

        ( width_, height_ ) =
            ( toString size.x, toString size.y )
    in
        rect
            [ fill "purple", x x_, y y_, width width_, height height_ ]
            []


gameOverLabel : Bool -> Svg msg
gameOverLabel isOver =
    if isOver then
        labelCustom
            [ textAnchor "middle", fill "red", fontSize "100" ]
            (res / 2)
            (res / 2)
            "Game Over"
    else
        label 0 0 ""


type VectorKind
    = Position
    | Velocity
    | Acceleration


vectorColor : VectorKind -> String
vectorColor kind =
    case kind of
        Position ->
            "blue"

        Velocity ->
            "green"

        Acceleration ->
            "red"


vector : VectorKind -> Vec2 -> Vec2 -> List (Svg msg)
vector kind start offset =
    let
        markerName =
            (toString kind) ++ "Marker"

        markerLink =
            "url(#" ++ markerName ++ ")"

        end =
            addVec2 start offset

        ( x1_, y1_, x2_, y2_ ) =
            ( toString start.x, toString start.y, toString end.x, toString end.y )
    in
        [ marker
            [ id markerName
            , viewBox "0 0 10 10"
            , refX "10"
            , refY "5"
            , markerUnits "strokeWidth"
            , markerWidth "6"
            , markerHeight "4"
            , orient "auto"
            , stroke (vectorColor kind)
            , fill (vectorColor kind)
            ]
            [ Svg.path [ d "M 0 0 L 10 5 L 0 10 z" ] [] ]
        , line
            [ x1 x1_
            , y1 y1_
            , x2 x2_
            , y2 y2_
            , strokeWidth "5"
            , stroke (vectorColor kind)
            , markerEnd markerLink
            ]
            []
        ]


vectors : Ball -> List (Svg msg)
vectors object =
    (vector Position (Vec2 0 0) object.position)
        ++ (vector Velocity object.position (scaleVec2 0.2 object.velocity))
        ++ (vector Acceleration object.position (scaleVec2 0.2 object.acceleration))


viewBoxString =
    String.join " " (List.map toString [ 0, 0, 1000, 1000 ])


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
         --    ++ (vectors model.ball)
        )
