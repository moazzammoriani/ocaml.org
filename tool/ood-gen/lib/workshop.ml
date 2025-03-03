module Role = struct
  type t = [ `Chair | `Co_chair ] [@@deriving show { with_path = false }]

  let of_string = function
    | "chair" -> Ok `Chair
    | "co-chair" -> Ok `Co_chair
    | s -> Error (`Msg ("Unknown role type: " ^ s))

  let of_yaml = Utils.of_yaml of_string "Expected a string for role type"
end

type important_date = { date : string; info : string }
[@@deriving of_yaml, show { with_path = false }]

type committee_member = {
  name : string;
  role : Role.t option;
  affiliation : string option;
  picture : string option;
}
[@@deriving of_yaml, show { with_path = false }]

type presentation = {
  title : string;
  authors : string list;
  link : string option;
  video : string option;
  slides : string option;
  poster : bool option;
  additional_links : string list option;
}
[@@deriving of_yaml, show { with_path = false }]

type metadata = {
  title : string;
  location : string;
  date : string;
  important_dates : important_date list;
  presentations : presentation list;
  program_committee : committee_member list;
  organising_committee : committee_member list;
}
[@@deriving of_yaml]

type t = {
  title : string;
  slug : string;
  location : string;
  date : string;
  important_dates : important_date list;
  presentations : presentation list;
  program_committee : committee_member list;
  organising_committee : committee_member list;
  toc_html : string;
  body_md : string;
  body_html : string;
}
[@@deriving
  stable_record ~version:metadata ~remove:[ slug; toc_html; body_md; body_html ],
    show { with_path = false }]

let of_metadata m = of_metadata m ~slug:(Utils.slugify m.title)

let decode (_, (head, body_md)) =
  let metadata = metadata_of_yaml head in
  let omd = Omd.of_string body_md in
  let toc_html = Omd.to_html (Omd.toc ~depth:4 omd) in
  let body_html = Omd.to_html omd in
  Result.map (of_metadata ~toc_html ~body_md ~body_html) metadata

let all () =
  Utils.map_files decode "workshops/*.md"
  |> List.sort (fun w1 w2 -> String.compare w2.date w1.date)

let template () =
  Format.asprintf
    {|
type role =
  [ `Chair
  | `Co_chair
  ]

type important_date = { date : string; info : string }

type committee_member = {
  name : string;
  role : role option;
  affiliation : string option;
  picture : string option;
}

type presentation = {
  title : string;
  authors : string list;
  link : string option;
  video : string option;
  slides : string option;
  poster : bool option;
  additional_links : string list option;
}

type t = {
  title : string;
  slug : string;
  location : string;
  date : string;
  important_dates : important_date list;
  presentations : presentation list;
  program_committee : committee_member list;
  organising_committee : committee_member list;
  toc_html : string;
  body_md : string;
  body_html : string;
}
  
let all = %a
|}
    (Fmt.brackets (Fmt.list pp ~sep:Fmt.semi))
    (all ())
