module Data.Modal exposing (Modal(..), init)


type Modal
    = CreateModal
    | ModifyModal
    | NoModal
    | ReadOnlyModal


init : Modal
init =
    NoModal
