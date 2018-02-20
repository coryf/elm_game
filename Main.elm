module Main exposing (main)

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import AnimationFrame
import Time exposing (Time)
import Keyboard
import Mouse
import Window
import String.Extra


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


scaleVec2 : Float -> Vec2 -> Vec2
scaleVec2 scalar v =
    { x = v.x * scalar, y = v.y * scalar }


addVec2 : Vec2 -> Vec2 -> Vec2
addVec2 v1 v2 =
    { x = v1.x + v2.x, y = v1.y + v2.y }


multVec2 : Vec2 -> Vec2 -> Vec2
multVec2 v1 v2 =
    { x = v1.x * v2.x, y = v1.y * v2.y }


type alias PhysicalObject =
    { position : Vec2
    , velocity : Vec2
    , acceleration : Vec2
    , restitution : Float -- Bouncability
    , radius : Float
    }


type alias Model =
    { player : PhysicalObject
    , secondsOffset : Float
    }


initPhysicalObject : PhysicalObject
initPhysicalObject =
    { position = Vec2 0 0
    , velocity = Vec2 0 0
    , acceleration = Vec2 0 0
    , restitution = -0.7
    , radius = 10
    }


model : Model
model =
    { player =
        { initPhysicalObject
            | position = Vec2 100 100
        }
    , secondsOffset = 0
    }


init : ( Model, Cmd Msg )
init =
    ( model, Cmd.none )



-- UPDATE


type Msg
    = KeyMsg Keyboard.KeyCode
    | FrameDiffMsg Time


gravity =
    9.8 * 500


applyGravity : PhysicalObject -> PhysicalObject
applyGravity t object =
    { object | acceleration = Vec2 0 (gravity * t) }


updateAcceleration : Time -> PhysicalObject -> PhysicalObject
updateAcceleration t object =
    object
        |> applyGravity t


addTimeScaledVec2 : Time -> Vec2 -> Vec2 -> Vec2
addTimeScaledVec2 t a b =
    addVec2 a (scaleVec2 t b)


updateVelocity : Time -> PhysicalObject -> PhysicalObject
updateVelocity t object =
    let
        o =
            updateAcceleration t object
    in
        { o | velocity = addTimeScaledVec2 t o.velocity o.acceleration }


updatePosition : Time -> PhysicalObject -> PhysicalObject
updatePosition t object =
    let
        o =
            updateVelocity t object
    in
        { o | position = addTimeScaledVec2 t o.position o.velocity }


collideWalls : PhysicalObject -> PhysicalObject
collideWalls ({ position, velocity, radius, restitution } as object) =
    let
        { x, y } =
            position

        ( vX, vY ) =
            ( velocity.x, velocity.y )

        ( wallStart, wallEnd ) =
            ( radius, 1000 - radius )

        bounceX =
            if (x > wallEnd && vX > 0) || (x < wallStart && vX < 0) then
                restitution
            else
                1

        bounceY =
            if (y > wallEnd && vY > 0) || (y < wallStart && vY < 0) then
                restitution
            else
                1
    in
        { object | velocity = multVec2 object.velocity (Vec2 bounceX bounceY) }


animate : Float -> Model -> Model
animate t model =
    { model
        | player =
            model.player
                |> updatePosition t
                |> collideWalls
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyMsg code ->
            ( model, Cmd.none )

        FrameDiffMsg timeDiff ->
            let
                t =
                    Time.inSeconds timeDiff
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


formatFloat : Int -> Float -> String
formatFloat places float =
    case places of
        0 ->
            float |> round |> toString

        _ ->
            let
                expandedString =
                    (float * (toFloat (10 ^ places))) |> round |> toString

                decimalPosition =
                    (expandedString |> String.length) - places
            in
                expandedString |> flip String.Extra.insertAt decimalPosition "."


background : Svg msg
background =
    rect
        [ fill "#ccc", x "0", y "0", width "1000", height "1000", rx "10", ry "10" ]
        []


scoreLabel : String -> Html msg
scoreLabel score =
    text_
        [ x "950", y "50", textAnchor "end", fontFamily "Helvetica", fontSize "32" ]
        [ text score ]


titleLabel : String -> Html msg
titleLabel title =
    text_
        [ x "50", y "50", fontFamily "Helvetica", fontSize "32" ]
        [ text title ]


player : PhysicalObject -> Svg msg
player { position, radius } =
    let
        { x, y } =
            position
    in
        circle
            [ fill "blue", cx (toString x), cy (toString y), r (toString radius) ]
            []


view : Model -> Html Msg
view model =
    svg
        [ width "100%", height "100%", viewBox "0 0 1000 1000" ]
        [ background
        , player model.player
        , titleLabel "A Game"
        , scoreLabel (toString model.secondsOffset)
        ]
