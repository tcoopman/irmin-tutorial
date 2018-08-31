#30 "src/Contents.md"
module Counter: Irmin.Contents.S with type t = int64 = struct
	type t = int64
	let t = Irmin.Type.int64
;;
#38 "src/Contents.md"
	let pp fmt = Format.fprintf fmt "%Ld"
;;
#44 "src/Contents.md"
	let of_string s =
		match Int64.of_string_opt s with
		| Some i -> Ok i
		| None -> Error (`Msg "invalid counter value")
;;
#55 "src/Contents.md"
	let merge ~old a b =
	    let open Irmin.Merge.Infix in
		old () >|=* fun old ->
        let old = match old with None -> 0L | Some o -> o in
        let (+) = Int64.add and (-) = Int64.sub in
        a + b - old
;;
#64 "src/Contents.md"
    let merge = Irmin.Merge.(option (v t merge))
end
;;
#71 "src/Contents.md"
let merge = Irmin.Merge.(option counter)
;;
#77 "src/Contents.md"
module Counter_mem_store = Irmin_mem.KV(Counter)
;;
#87 "src/Contents.md"
type color =
    | Black
    | White
    | Other of string
type car = {
    license: string;
    year: int32;
    make_and_model: string * string;
    color: color;
    owner: string;
}
;;
#103 "src/Contents.md"
module Car = struct
    type t  = car
    let color =
        let open Irmin.Type in
        variant "color" (fun black white other -> function
            | Black -> black
            | White -> white
            | Other color -> other color)
        |~ case0 "Black" Black
        |~ case0 "White" White
        |~ case1 "Other" string (fun s -> Other s)
        |> sealv
;;
#120 "src/Contents.md"
    let t =
        let open Irmin.Type in
        record "car" (fun license year make_and_model color owner ->
            {license; year; make_and_model; color; owner})
        |+ field "license" string (fun t -> t.license)
        |+ field "year" int32 (fun t -> t.year)
        |+ field "make_and_model" (pair string string) (fun t -> t.make_and_model)
        |+ field "color" color (fun t -> t.color)
        |+ field "owner" string (fun t -> t.owner)
        |> sealr
;;
#135 "src/Contents.md"
	let pp = Irmin.Type.pp_json t
;;
#141 "src/Contents.md"
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json t decoder
;;
#149 "src/Contents.md"
    let merge = Irmin.Merge.(option (idempotent t))
end
;;
#156 "src/Contents.md"
module Car_store = Irmin_mem.KV(Car)
;;
#188 "src/Contents.md"

#196 "src/Contents.md"
module Object = struct
    type t = (string * string) list
    let t = Irmin.Type.(list (pair string string))
;;
#206 "src/Contents.md"
	let pp = Irmin.Type.pp_json t
;;
#212 "src/Contents.md"
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json t decoder
;;
#221 "src/Contents.md"
    let merge_alist =
        Irmin.Merge.(alist Irmin.Type.string Irmin.Type.string (fun _key -> option string))
    let merge = Irmin.Merge.(option merge_alist)
end
;;
#8 "src/UsingTheCommandLine.md"

#14 "src/UsingTheCommandLine.md"

#22 "src/UsingTheCommandLine.md"

#28 "src/UsingTheCommandLine.md"

#39 "src/UsingTheCommandLine.md"

#58 "src/UsingTheCommandLine.md"

#70 "src/UsingTheCommandLine.md"

#77 "src/UsingTheCommandLine.md"

#87 "src/UsingTheCommandLine.md"

#91 "src/UsingTheCommandLine.md"

#97 "src/UsingTheCommandLine.md"

#101 "src/UsingTheCommandLine.md"

#107 "src/UsingTheCommandLine.md"

#111 "src/UsingTheCommandLine.md"

#16 "src/GettingStartedOCaml.md"
module Mem_store = Irmin_mem.KV(Irmin.Contents.String)
;;
#22 "src/GettingStartedOCaml.md"
module Git_store = Irmin_unix.Git.FS.KV(Irmin.Contents.Json)
;;
#30 "src/GettingStartedOCaml.md"
module Mem_Store =
    Irmin_mem.Make
        (Irmin.Metadata.None)
        (Irmin.Contents.Json)
        (Irmin.Path.String_list)
        (Irmin.Branch.String)
        (Irmin.Hash.SHA1)
;;
#44 "src/GettingStartedOCaml.md"
let git_config = Irmin_git.config ~bare:true "/tmp/irmin"
;;
#48 "src/GettingStartedOCaml.md"
let config = Irmin_mem.config ()
;;
#54 "src/GettingStartedOCaml.md"
let git_repo = Git_store.Repo.v git_config
;;
#58 "src/GettingStartedOCaml.md"
let repo = Mem_store.Repo.v config
;;
#68 "src/GettingStartedOCaml.md"
open Lwt.Infix
;;
#73 "src/GettingStartedOCaml.md"

#77 "src/GettingStartedOCaml.md"
let branch config name =
    Mem_store.Repo.v config >>= fun repo ->
    Mem_store.of_branch repo name
;;
#87 "src/GettingStartedOCaml.md"
let info message = Irmin_unix.info ~author:"Example" "%s"
;;
#98 "src/GettingStartedOCaml.md"

#104 "src/GettingStartedOCaml.md"
let transaction_example =
Mem_store.Repo.v config >>= Mem_store.master >>= fun t ->
let info = Irmin_unix.info "example transaction" in
Mem_store.with_tree t [] ~info ~strategy:`Set (fun tree ->
    let tree = match tree with Some t -> t | None -> Mem_store.Tree.empty in
    Mem_store.Tree.remove tree ["foo"; "bar"] >>= fun tree ->
    Mem_store.Tree.add tree ["a"; "b"; "c"] "123" >>= fun tree ->
    Mem_store.Tree.add tree ["d"; "e"; "f"] "456" >>= Lwt.return_some)
let () = Lwt_main.run transaction_example
;;
#120 "src/GettingStartedOCaml.md"
let move t ~src ~dest =
    Mem_store.with_tree t Mem_store.Key.empty (fun tree ->
        match tree with
        | Some tr ->
            Mem_store.Tree.get_tree tr src >>= fun v ->
            Mem_store.Tree.remove tr src >>= fun _ ->
            Mem_store.Tree.add_tree tr dest v >>= Lwt.return_some
        | None -> Lwt.return_none
    )
let main =
    Mem_store.Repo.v config >>= Mem_store.master >>= fun t ->
    let info = Irmin_unix.info "move a -> foo" in
    move t ~src:["a"] ~dest:["foo"] ~info
let () = Lwt_main.run main
;;
#149 "src/GettingStartedOCaml.md"
open Irmin_unix
module Git_mem_store = Git.Mem.KV(Irmin.Contents.String)
module Sync = Irmin.Sync(Git_mem_store)
let remote = Irmin.remote_uri "git://github.com/mirage/irmin.git"
let main =
    Git_mem_store.Repo.v config >>= Git_mem_store.master >>= fun t ->
    Sync.pull_exn t remote `Set >>= fun () ->
    Git_mem_store.list t [] >|= List.iter (fun (step, kind) ->
        match kind with
        | `Contents -> Printf.printf "FILE %s\n" step
        | `Node -> Printf.printf "DIR %s\n" step
    )
let () = Lwt_main.run main
;;
#22 "src/Backend.md"
open Lwt.Infix
open Hiredis
;;
#27 "src/Backend.md"
module RO (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  type t = (string * Client.t) (* Store type: Redis prefix and client *)
  type key = K.t               (* Key type *)
  type value = V.t             (* Value type *)
;;
#43 "src/Backend.md"
  let v prefix config =
    let module C = Irmin.Private.Conf in
    let root = match C.get config Irmin.Private.Conf.root with
      | Some root -> root ^ ":" ^ prefix ^ ":"
      | None -> prefix ^ ":"
    in
    Lwt.return (root, Client.connect ~port:6379 "127.0.0.1")
;;
#55 "src/Backend.md"
  let mem (prefix, client) key =
      let key = Fmt.to_to_string K.pp key in
      match Client.run client [| "EXISTS"; prefix ^ key |] with
      | Integer 1L -> Lwt.return_true
      | _ -> Lwt.return_false
;;
#65 "src/Backend.md"
  let find (prefix, client) key =
      let key = Fmt.to_to_string K.pp key in
      match Client.run client [| "GET"; prefix ^ key |] with
      | String s ->
          (match V.of_string s with
          | Ok s -> Lwt.return_some s
          | _ -> Lwt.return_none)
      | _ -> Lwt.return_none
end
;;
#81 "src/Backend.md"
module AO (K: Irmin.Hash.S) (V: Irmin.Contents.Conv) = struct
  include RO(K)(V)
  let v = v "obj"
;;
#89 "src/Backend.md"
  let add (prefix, client) value =
      let hash = K.digest V.t value in
      let key = Fmt.to_to_string K.pp hash in
      let value = Fmt.to_to_string V.pp value in
      ignore (Client.run client [| "SET"; prefix ^ key; value |]);
      Lwt.return hash
end
;;
#103 "src/Backend.md"
module Link (K: Irmin.Hash.S) = struct
  include RO(K)(K)
  let v = v "link"
;;
#111 "src/Backend.md"
  let add (prefix, client) index key =
      let key = Fmt.to_to_string K.pp key in
      let index = Fmt.to_to_string K.pp index in
      ignore (Client.run client [| "SET"; prefix ^ index; key |]);
      Lwt.return_unit
end
;;
#126 "src/Backend.md"
module RW (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  module RO = RO(K)(V)
;;
#133 "src/Backend.md"
  module W = Irmin.Private.Watch.Make(K)(V)
  type t = { t: RO.t; w: W.t }  (* Store type *)
  type key = RO.key             (* Key type *)
  type value = RO.value         (* Value type *)
  type watch = W.watch          (* Watch type *)
;;
#143 "src/Backend.md"
  let watches = W.v ()
;;
#149 "src/Backend.md"
  let v config =
    RO.v "data" config >>= fun t ->
    Lwt.return {t; w = watches }
;;
#157 "src/Backend.md"
  let find t = RO.find t.t
  let mem t  = RO.mem t.t
;;
#164 "src/Backend.md"
  let watch_key t key = W.watch_key t.w key
  let watch t = W.watch t.w
  let unwatch t = W.unwatch t.w
;;
#179 "src/Backend.md"
  let list {t = (prefix, client); _} =
      match Client.run client [| "KEYS"; prefix ^ "*" |] with
      | Array arr ->
          Array.map (fun k ->
            K.of_string (Value.to_string k)
          ) arr
          |> Array.to_list
          |> Lwt_list.filter_map_s (function
            | Ok s -> Lwt.return_some s
            | _ -> Lwt.return_none)
      | _ -> Lwt.return []
;;
#195 "src/Backend.md"
  let set {t = (prefix, client); w} key value =
      let key' = Fmt.to_to_string K.pp key in
      let value' = Fmt.to_to_string V.pp value in
      match Client.run client [| "SET"; prefix ^ key'; value' |] with
      | Status "OK" -> W.notify w key (Some value)
      | _ -> Lwt.return_unit
;;
#206 "src/Backend.md"
  let remove {t = (prefix, client); w} key =
      let key' = Fmt.to_to_string K.pp key in
      ignore (Client.run client [| "DEL"; prefix ^ key' |]);
      W.notify w key None
;;
#215 "src/Backend.md"
  let test_and_set t key ~test ~set:set_value =
    (* A helper function to execute a command in a Redis transaction *)
    let txn client args =
      ignore @@ Client.run client [| "MULTI" |];
      ignore @@ Client.run client args;
      Client.run client [| "EXEC" |] <> Nil
    in
    let prefix, client = t.t in
    let key' = Fmt.to_to_string K.pp key in
    (* Start watching the key in question *)
    ignore @@ Client.run client [| "WATCH"; prefix ^ key' |];
    (* Get the existing value *)
    find t key >>= fun v ->
    (* Check it against [test] *)
    if Irmin.Type.(equal (option V.t)) test v then (
      (match set_value with
        | None -> (* Remove the key *)
            if txn client [| "DEL"; prefix ^ key' |] then
              W.notify t.w key None >>= fun () ->
              Lwt.return_true
            else
              Lwt.return_false
        | Some value -> (* Update the key *)
            let value' = Fmt.to_to_string V.pp value in
            if txn client [| "SET"; prefix ^ key'; value' |] then
              W.notify t.w key set_value >>= fun () ->
              Lwt.return_true
            else
              Lwt.return_false
      ) >>= fun ok ->
      Lwt.return ok
    ) else (
      ignore @@ Client.run client [| "UNWATCH"; prefix ^ key' |];
      Lwt.return_false
    )
end
;;
#256 "src/Backend.md"
module Make = Irmin.Make(AO)(RW)
;;
#266 "src/Backend.md"

