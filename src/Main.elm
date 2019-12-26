port module Main exposing (main)

import Array
import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, button, dd, div, dl, dt, h2, li, ol, p, strong, text, textarea, ul)
import Html.Attributes exposing (class, cols, rows)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import Random
import Random.List exposing (shuffle)


port storage : Encode.Value -> Cmd msg


storeModel : Model -> Cmd msg
storeModel model =
    storage (encodeModel model)


encodeModel : Model -> Encode.Value
encodeModel { state, candidates, choices, round, currentPosition } =
    Encode.object
        [ ( "state", encodeState state )
        , ( "candidates", Encode.list encodeCandidate candidates )
        , ( "choices", Encode.list encodeCandidate choices )
        , ( "round", Encode.int round )
        , ( "currentPosition", Encode.int currentPosition )
        ]


encodeState : State -> Encode.Value
encodeState state =
    let
        val =
            case state of
                NoNames ->
                    "NoNames"

                Preview ->
                    "Preview"

                ShowPairing ->
                    "ShowPairing"

                Done ->
                    "Done"
    in
    Encode.string val


encodeCandidate : Candidate -> Encode.Value
encodeCandidate { name, ranking, score, eliminatedBy } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "ranking", encodeMaybe Encode.int ranking )
        , ( "eliminatedBy", encodePossibleCandidate eliminatedBy )
        , ( "score", Encode.int score )
        ]


encodePossibleCandidate : PossibleCandidate -> Encode.Value
encodePossibleCandidate possibleCandidate =
    let
        unwrapped =
            case possibleCandidate of
                PossibleCandidate c ->
                    c
    in
    case unwrapped of
        Nothing ->
            Encode.null

        Just c ->
            encodeCandidate c


encodeMaybe : (a -> Encode.Value) -> Maybe a -> Encode.Value
encodeMaybe f a =
    case a of
        Just val ->
            f val

        Nothing ->
            Encode.null



-- { state : State
--     , candidates : List Candidate
--     , round : Int
--     , choices : List Candidate
--     , currentPosition : Int
--     }
-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onKeyDown keyDecoder


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map keyToMsg (Decode.field "key" Decode.string)


keyToMsg : String -> Msg
keyToMsg string =
    case string of
        "ArrowRight" ->
            Pressed Right

        "ArrowLeft" ->
            Pressed Left

        "ArrowUp" ->
            Pressed Middle

        "ArrowDown" ->
            Pressed Middle

        _ ->
            None



-- MODEL


type alias Model =
    { state : State
    , candidates : List Candidate
    , round : Int
    , choices : List Candidate
    , currentPosition : Int
    }


type alias Candidate =
    { name : String
    , ranking : Maybe Int
    , eliminatedBy : PossibleCandidate
    , score : Int
    }


type PossibleCandidate
    = PossibleCandidate (Maybe Candidate)


nameToCandidate : String -> Candidate
nameToCandidate name =
    { name = name
    , ranking = Nothing
    , eliminatedBy = PossibleCandidate Nothing
    , score = 1
    }


namesToCandidates : List String -> List Candidate
namesToCandidates names =
    let
        trimmed =
            List.map String.trim names

        filtered =
            List.filter (String.trim >> String.isEmpty >> Basics.not) trimmed
    in
    List.map nameToCandidate filtered


getPairing : Int -> List Candidate -> Pairing
getPairing number candidates =
    let
        isAvailable : Candidate -> Bool
        isAvailable candidate =
            let
                eliminatedBy =
                    case candidate.eliminatedBy of
                        PossibleCandidate c ->
                            c
            in
            candidate.ranking == Nothing && eliminatedBy == Nothing

        available =
            List.filter isAvailable candidates

        sorted =
            List.sortBy .score available |> List.reverse
    in
    case available of
        [] ->
            Impossible

        [ one ] ->
            JustOne one

        _ ->
            Next (List.take number sorted)


resolveNextPairing : Model -> ( Model, Cmd Msg )
resolveNextPairing model =
    case getPairing 3 model.candidates of
        Next choices ->
            updateWithStore { model | choices = choices, state = ShowPairing, round = model.round + 1 }

        Impossible ->
            updateWithStore { model | state = Done }

        JustOne last ->
            let
                resolveCandidate : Candidate -> Candidate
                resolveCandidate candidate =
                    if candidate == last then
                        { candidate | ranking = Just model.currentPosition }

                    else
                        case candidate.eliminatedBy of
                            PossibleCandidate pc ->
                                case pc of
                                    Just c ->
                                        if c.name == last.name then
                                            { candidate | eliminatedBy = PossibleCandidate Nothing }

                                        else
                                            candidate

                                    Nothing ->
                                        candidate

                resolvedCandidates =
                    List.map resolveCandidate model.candidates

                newModel =
                    { model
                        | candidates = resolvedCandidates
                        , currentPosition = model.currentPosition + 1
                    }
            in
            ( newModel, shuffleCandidatesCommand newModel.candidates )


resolvePick : Model -> Candidate -> ( Model, Cmd Msg )
resolvePick model picked =
    let
        loosers =
            List.filter ((==) picked >> not) model.choices

        newScore =
            List.map .score loosers |> List.foldl (+) picked.score

        resolveCandidate : Candidate -> Candidate -> Candidate
        resolveCandidate choice candidate =
            if candidate == choice then
                if choice == picked then
                    { candidate | score = newScore }

                else
                    { candidate | eliminatedBy = PossibleCandidate (Just picked) }

            else
                candidate

        resolveChoice : Candidate -> List Candidate -> List Candidate
        resolveChoice choice candidates =
            List.map (resolveCandidate choice) candidates

        newCandidates =
            List.foldl resolveChoice model.candidates model.choices
    in
    resolveNextPairing { model | candidates = newCandidates }


type Pairing
    = Next (List Candidate)
    | JustOne Candidate
    | Impossible


type State
    = NoNames
    | Preview
    | ShowPairing
    | Done


init : Decode.Value -> ( Model, Cmd Msg )
init data =
    ( decodeModel data, Cmd.none )


initialModel : Model
initialModel =
    { state = NoNames
    , candidates = []
    , round = 0
    , currentPosition = 0
    , choices = []
    }


modelDecoder : Decode.Decoder Model
modelDecoder =
    Decode.succeed Model
        |> andMap (Decode.field "state" stateDecoder)
        |> andMap (Decode.field "candidates" (Decode.list candidateDecoder))
        |> andMap (Decode.field "round" Decode.int)
        |> andMap (Decode.field "choices" (Decode.list candidateDecoder))
        |> andMap (Decode.field "currentPosition" Decode.int)


decodeModel : Decode.Value -> Model
decodeModel value =
    let
        decoded =
            Decode.decodeValue modelDecoder value
    in
    case decoded of
        Ok v ->
            v

        Err _ ->
            initialModel


candidateDecoder : Decode.Decoder Candidate
candidateDecoder =
    Decode.succeed Candidate
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "ranking" (Decode.maybe Decode.int))
        |> andMap (Decode.field "eliminatedBy" (Decode.lazy (\_ -> possibleCandidateDecoder)))
        |> andMap (Decode.field "score" Decode.int)


possibleCandidateDecoder : Decode.Decoder PossibleCandidate
possibleCandidateDecoder =
    Decode.nullable candidateDecoder |> Decode.map PossibleCandidate


stateDecoder : Decode.Decoder State
stateDecoder =
    let
        stringToState : String -> Decode.Decoder State
        stringToState str =
            case str of
                "NoNames" ->
                    Decode.succeed NoNames

                "Preview" ->
                    Decode.succeed Preview

                "ShowPairing" ->
                    Decode.succeed ShowPairing

                "Done" ->
                    Decode.succeed Done

                _ ->
                    Decode.succeed NoNames
    in
    Decode.string |> Decode.andThen stringToState



-- UPDATE


type Msg
    = None
    | Start
    | Restart
    | RawCandidates String
    | PreviewConfirm
    | Shuffled (List Candidate)
    | Pick Candidate
    | Pressed Position


type Position
    = Left
    | Middle
    | Right


updateWithStore : Model -> ( Model, Cmd Msg )
updateWithStore model =
    ( model, storeModel model )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        None ->
            ( model, Cmd.none )

        Restart ->
            updateWithStore initialModel

        Start ->
            updateWithStore { model | state = Preview }

        RawCandidates raw ->
            let
                names =
                    String.lines raw
            in
            updateWithStore { model | candidates = namesToCandidates names }

        Shuffled candidates ->
            resolveNextPairing { model | candidates = candidates }

        PreviewConfirm ->
            ( { model | currentPosition = 1 }, shuffleCandidatesCommand model.candidates )

        Pick candidate ->
            resolvePick model candidate

        Pressed position ->
            case model.state of
                ShowPairing ->
                    let
                        choiceArray =
                            Array.fromList model.choices

                        candidate =
                            case position of
                                Left ->
                                    Array.get 0 choiceArray

                                Right ->
                                    if Array.length choiceArray == 2 then
                                        Array.get 1 choiceArray

                                    else
                                        Array.get 2 choiceArray

                                Middle ->
                                    Array.get 1 choiceArray
                    in
                    case candidate of
                        Just c ->
                            resolvePick model c

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


shuffleCandidatesCommand : List Candidate -> Cmd Msg
shuffleCandidatesCommand candidates =
    Random.generate Shuffled (shuffle candidates)



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ renderHeader
        , renderMain model

        --, debugRenderModel model
        ]


renderHeader : Html Msg
renderHeader =
    div [ class "header" ]
        [ text "Boardgame Ranking Tool (aka BRT)"
        , button [ onClick Restart, class "small inverse" ] [ text "Restart" ]
        ]


renderHeading : (List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg) -> String -> Html Msg
renderHeading h txt =
    h [] [ text txt ]


renderStrong : String -> Html Msg
renderStrong txt =
    strong [] [ text txt ]


debugRenderModel : Model -> Html Msg
debugRenderModel model =
    div []
        [ renderHeading h2 "Debug data"
        , dl []
            [ dt [] [ renderStrong "state" ]
            , dd [] [ debugRenderState model.state ]
            , dt [] [ renderStrong "candidates" ]
            , dd [] (debugRenderCandidates model.candidates)
            , dt [] [ renderStrong "round" ]
            , dd [] [ text (String.fromInt model.round) ]
            , dt [] [ renderStrong "choices" ]
            , dd [] (debugRenderCandidates model.choices)
            , dt [] [ renderStrong "currentPosition" ]
            , dd [] [ text (String.fromInt model.currentPosition) ]
            ]
        ]


debugRenderCandidate : Candidate -> Html Msg
debugRenderCandidate candidate =
    dl []
        [ dt [] [ text "name" ]
        , dd [] [ renderStrong candidate.name ]
        , dt [] [ text "ranking" ]
        , dd [] [ debugRenderRanking candidate.ranking ]
        , dt [] [ text "eliminatedBy" ]
        , dd [] [ debugRenderEliminatedBy candidate.eliminatedBy ]
        , dt [] [ text "score" ]
        , dd [] [ text (String.fromInt candidate.score) ]
        ]


debugRenderRanking : Maybe Int -> Html Msg
debugRenderRanking int =
    case int of
        Nothing ->
            text "-"

        Just i ->
            text (String.fromInt i)


debugRenderEliminatedBy : PossibleCandidate -> Html Msg
debugRenderEliminatedBy (PossibleCandidate candidate) =
    case candidate of
        Nothing ->
            text "-"

        Just c ->
            text c.name


debugRenderCandidates : List Candidate -> List (Html Msg)
debugRenderCandidates candidates =
    List.map debugRenderCandidate candidates


debugRenderState : State -> Html Msg
debugRenderState state =
    case state of
        NoNames ->
            text "NoNames"

        Preview ->
            text "Preview"

        ShowPairing ->
            text "ShowPairing"

        Done ->
            text "Done"


renderMain : Model -> Html Msg
renderMain model =
    div [ class "main" ]
        (case model.state of
            NoNames ->
                renderSetup model

            Preview ->
                renderConfirm model

            ShowPairing ->
                renderPairing model

            Done ->
                renderDone model
        )


renderDone : Model -> List (Html Msg)
renderDone model =
    [ text ("You are done in " ++ String.fromInt model.round ++ " rounds!"), renderRankings model.candidates ]


renderSetup : Model -> List (Html Msg)
renderSetup model =
    [ renderHeading h2 "Welcome to BRT"
    , p [] [ text "First you need to enter some boardgames to rank" ]
    , p [] [ text "Please enter all boardgames to rank in the area below, putting each boardgame name on its own line" ]
    , textarea
        [ rows 20
        , cols 100
        , onInput RawCandidates
        ]
        []
    , p
        []
        [ text
            (String.concat
                [ "Entered "
                , model.candidates |> List.length |> String.fromInt
                , " candidates"
                ]
            )
        ]
    , button [ onClick Start, class "primary" ] [ text "Done" ]
    ]


renderConfirm : Model -> List (Html Msg)
renderConfirm model =
    [ renderHeading h2 "Theese are the candidates to be ranked"
    , ul [] (List.map (\obj -> li [] [ text obj.name ]) model.candidates)
    , div [] [ button [ onClick PreviewConfirm, class "primary" ] [ text "Start ranking" ] ]
    ]


renderPairing : Model -> List (Html Msg)
renderPairing model =
    [ renderHeading h2 ("Pairing nr. " ++ String.fromInt model.round)
    , p [] [ text "From the candidates below choose the one which you like the best" ]
    , div [ class "picking" ]
        [ div [ class "choices" ] (renderPairingCandidates model.choices)
        , div [ class "rankings" ] [ renderRankings model.candidates ]
        ]
    ]


renderRankings : List Candidate -> Html Msg
renderRankings candidates =
    ol [] (List.sortWith sortByRank candidates |> List.map renderRankedItem)


sortByRank : Candidate -> Candidate -> Order
sortByRank c1 c2 =
    case c1.ranking of
        Nothing ->
            GT

        Just r1 ->
            case c2.ranking of
                Nothing ->
                    LT

                Just r2 ->
                    compare r1 r2


renderRankedItem : Candidate -> Html Msg
renderRankedItem candidate =
    case candidate.ranking of
        Nothing ->
            li [] []

        Just _ ->
            li [] [ text candidate.name ]


renderPairingCandidates : List Candidate -> List (Html Msg)
renderPairingCandidates candidates =
    List.map renderPairingCandidate candidates


renderPairingCandidate : Candidate -> Html Msg
renderPairingCandidate candidate =
    button [ onClick (Pick candidate), class "primary" ] [ text candidate.name ]
