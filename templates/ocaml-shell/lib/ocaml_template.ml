open Base
open Stdio

(** A simple greeting function that demonstrates string manipulation *)
let greet ?(greeting = "Hello") name =
  Printf.sprintf "%s, %s!" greeting (String.capitalize name)

(** Mathematical utilities *)
module Math = struct
  (** Calculate fibonacci number *)
  let rec fibonacci n =
    if n <= 1 then n
    else fibonacci (n - 1) + fibonacci (n - 2)

  (** Check if a number is prime *)
  let is_prime n =
    if n < 2 then false
    else
      let rec check i =
        if i * i > n then true
        else if n % i = 0 then false
        else check (i + 1)
      in
      check 2

  (** Generate list of prime numbers up to n *)
  let primes_up_to n =
    List.range 2 n |> List.filter ~f:is_prime
end

(** JSON utilities using Yojson *)
module Json_utils = struct
  type person = {
    name : string;
    age : int;
    email : string option;
  }

  let person_to_json { name; age; email } =
    let email_json = match email with
      | Some e -> `String e
      | None -> `Null
    in
    `Assoc [
      ("name", `String name);
      ("age", `Int age);
      ("email", email_json);
    ]

  let person_from_json = function
    | `Assoc assoc ->
      let name = match List.Assoc.find assoc ~equal:String.equal "name" with
        | Some (`String s) -> s
        | _ -> failwith "Missing or invalid name"
      in
      let age = match List.Assoc.find assoc ~equal:String.equal "age" with
        | Some (`Int i) -> i
        | _ -> failwith "Missing or invalid age"
      in
      let email = match List.Assoc.find assoc ~equal:String.equal "email" with
        | Some (`String s) -> Some s
        | Some `Null | None -> None
        | _ -> failwith "Invalid email"
      in
      { name; age; email }
    | _ -> failwith "Expected JSON object"
end

(** Async utilities using Lwt *)
module Async_utils = struct
  open Lwt.Syntax

  (** Simulate an async operation *)
  let async_greet ?(delay = 1.0) name =
    let* () = Lwt_unix.sleep delay in
    Lwt.return (greet name)

  (** Process a list of items asynchronously *)
  let async_map_p f lst =
    lst |> List.map ~f |> Lwt.all

  (** Timeout wrapper for async operations *)
  let with_timeout ~timeout f =
    Lwt.pick [
      f ();
      (let* () = Lwt_unix.sleep timeout in
       Lwt.fail_with "Operation timed out");
    ]
end

(** Logging utilities *)
module Logger = struct
  let setup_logging level =
    Logs.set_level level;
    Logs.set_reporter (Logs_fmt.reporter ())

  let info msg = Logs.info (fun m -> m "%s" msg)
  let warn msg = Logs.warn (fun m -> m "%s" msg)  
  let error msg = Logs.err (fun m -> m "%s" msg)
  let debug msg = Logs.debug (fun m -> m "%s" msg)
end