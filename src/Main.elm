module Main exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, button, dd, div, dl, dt, h1, h2, li, ol, p, strong, text, textarea, ul)
import Html.Attributes exposing (class, cols, rows)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Random
import Random.List exposing (shuffle)



-- MAIN


main : Program () Model Msg
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
            None

        "ArrowLeft" ->
            None

        "ArrowUp" ->
            None

        "ArrowDown" ->
            None

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
            ( { model | choices = choices, state = ShowPairing, round = model.round + 1 }, Cmd.none )

        Impossible ->
            ( { model | state = Done }, Cmd.none )

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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = NoNames
      , candidates = []
      , round = 0
      , currentPosition = 0
      , choices = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = None
    | Start
    | RawCandidates String
    | PreviewConfirm
    | Shuffled (List Candidate)
    | Pick Candidate


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        None ->
            ( model, Cmd.none )

        Start ->
            ( { model | state = Preview }, Cmd.none )

        RawCandidates raw ->
            let
                names =
                    String.lines raw
            in
            ( { model | candidates = namesToCandidates names }, Cmd.none )

        Shuffled candidates ->
            resolveNextPairing { model | candidates = candidates }

        PreviewConfirm ->
            ( { model | currentPosition = 1 }, shuffleCandidatesCommand model.candidates )

        Pick candidate ->
            resolvePick model candidate


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
    div [ class "header" ] [ text "Boardgame Ranking Tool (aka BRT)" ]


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
    , button [ onClick Start ] [ text "Done" ]
    ]


renderConfirm : Model -> List (Html Msg)
renderConfirm model =
    [ renderHeading h2 "Theese are the candidates to be ranked"
    , ul [] (List.map (\obj -> li [] [ text obj.name ]) model.candidates)
    , div [] [ button [ onClick PreviewConfirm ] [ text "Start ranking" ] ]
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
    button [ onClick (Pick candidate) ] [ text candidate.name ]
