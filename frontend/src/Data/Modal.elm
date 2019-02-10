module Data.Modal exposing (Modal(..), init)


type Modal
    = NoModal
    | ModifyModal
    | CreateModal


init : Modal
init =
    NoModal
