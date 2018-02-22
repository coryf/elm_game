module Main exposing (main)

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import AnimationFrame
import Time exposing (Time)
import Keyboard
import Mouse
import Window


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


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


type alias Ball =
    { position : Vec2
    , velocity : Vec2
    , acceleration : Vec2
    , restitution : Float
    , radius : Float
    }


type alias Paddle =
    { position : Vec2
    , size : Vec2
    }


type alias Model =
    { ball : Ball
    , paddle : Paddle
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
        { position = Vec2 500 900
        , size = Vec2 300 10
        }
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- UPDATE


type Msg
    = KeyMsg Keyboard.KeyCode
    | FrameDiffMsg Time


gravity =
    9.8 * 100


applyGravity : Ball -> Ball
applyGravity object =
    { object | acceleration = Vec2 0 gravity }


updatePosition : Time -> Ball -> Ball
updatePosition t object =
    { object
        | position = addVec2 object.position (scaleVec2 t object.velocity)
        , velocity = addVec2 object.velocity (scaleVec2 t object.acceleration)
        , acceleration =
            object
                |> applyGravity
                |> .acceleration
    }


collideWalls : Vec2 -> Ball -> Ball
collideWalls prevPosition ({ radius } as ball) =
    let
        { x, y } =
            ball.position

        ( movingLeft, movingUp ) =
            ( ball.velocity.x < 0, ball.velocity.y < 0 )

        ( hitLeft, hitRight, hitTop, hitBottom ) =
            ( x < radius, x > 1000 - radius, y < radius, y > 1000 - radius )

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
        { ball | velocity = multVec2 ball.velocity (Vec2 bounceX bounceY) }


collidePaddle : Vec2 -> Paddle -> Ball -> Ball
collidePaddle prevPosition paddle ({ position, radius, velocity } as ball) =
    let
        ballLine =
            ( prevPosition, ball.position )

        ( left, top ) =
            ( paddle.position.x, paddle.position.y - radius )

        ( right, bottom ) =
            ( left + paddle.size.x, top + paddle.size.y + (radius * 2) )

        topLine =
            ( Vec2 left top, Vec2 right top )

        bottomLine =
            ( Vec2 left bottom, Vec2 right bottom )

        crossTop =
            segmentIntersects ballLine topLine && velocity.y > 0

        crossBottom =
            segmentIntersects ballLine bottomLine && velocity.y < 0

        bounceY =
            crossTop || crossBottom
    in
        if bounceY then
            { ball | velocity = multVec2 velocity (Vec2 1 ball.restitution) }
        else
            ball


animate : Float -> Model -> Model
animate t model =
    let
        prevPosition =
            model.ball.position
    in
        { model
            | ball =
                model.ball
                    |> updatePosition t
                    |> collideWalls prevPosition
                    |> collidePaddle prevPosition model.paddle
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyMsg code ->
            case code of
                _ ->
                    ( model, Cmd.none )

        FrameDiffMsg timeDiff ->
            let
                t =
                    1 / 60

                --Time.inSeconds timeDiff
            in
                ( animate t model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyMsg
        , AnimationFrame.diffs FrameDiffMsg
        ]



-- VIEW


res =
    1000


background : Svg msg
background =
    rect
        [ fill "#ccc", x "0", y "0", width "1000", height "1000", rx "10", ry "10" ]
        []


labelCustom : List (Svg.Attribute msg) -> Float -> Float -> String -> Svg msg
labelCustom attrs x_ y_ string =
    text_
        ([ x (toString x_), y (toString y_), fontFamily "Helvetica", fontSize "32" ] ++ attrs)
        [ text string ]


label : Float -> Float -> String -> Svg msg
label =
    labelCustom []


scoreLabel : String -> Svg msg
scoreLabel =
    labelCustom [ textAnchor "end" ] 950 50


titleLabel : String -> Svg msg
titleLabel =
    label 50 50


ball : Ball -> Svg msg
ball { position, radius } =
    let
        { x, y } =
            position
    in
        circle
            [ fill "blue", cx (toString x), cy (toString y), r (toString radius) ]
            []


paddle : Paddle -> Svg msg
paddle { position, size } =
    let
        ( x_, y_ ) =
            ( toString position.x, toString position.y )

        ( width_, height_ ) =
            ( toString size.x, toString size.y )
    in
        rect
            [ fill "purple", x x_, y y_, width width_, height height_ ]
            []


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
            [ id markerName, viewBox "0 0 10 10", refX "10", refY "5", markerUnits "strokeWidth", markerWidth "6", markerHeight "4", orient "auto", stroke (vectorColor kind), fill (vectorColor kind) ]
            [ Svg.path [ d "M 0 0 L 10 5 L 0 10 z" ] [] ]
        , line
            [ x1 x1_, y1 y1_, x2 x2_, y2 y2_, strokeWidth "5", stroke (vectorColor kind), markerEnd markerLink ]
            []
        ]


vectors : Ball -> List (Svg msg)
vectors object =
    (vector Position (Vec2 0 0) object.position)
        ++ (vector Velocity object.position (scaleVec2 0.2 object.velocity))
        ++ (vector Acceleration object.position (scaleVec2 0.2 object.acceleration))


view : Model -> Html Msg
view model =
    svg
        [ width "100%", height "100%", viewBox "0 0 1000 1000" ]
        ([ background
         , titleLabel "A Game"
         , scoreLabel "1000"
         , ball model.ball
         , paddle model.paddle
         ]
            ++ (vectors model.ball)
        )
