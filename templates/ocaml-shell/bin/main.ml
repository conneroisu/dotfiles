open Base
open Stdio
open Ocaml_template

(** Simple main without complex Cmdliner usage for now *)

let () =
  printf "=== OCaml Template CLI ===\n";
  
  (* Setup logging *)
  Logger.setup_logging (Some Logs.Info);
  Logger.info "Starting OCaml Template";
  
  (* Basic greeting *)
  printf "Basic greeting: %s\n" (greet "OCaml");
  
  (* Math examples *)
  printf "Fibonacci(8) = %d\n" (Math.fibonacci 8);
  printf "Is 13 prime? %b\n" (Math.is_prime 13);
  printf "Primes up to 30: %s\n" 
    (Math.primes_up_to 30 |> List.map ~f:Int.to_string |> String.concat ~sep:", ");
  
  (* JSON example *)
  let person = Json_utils.{ name = "Example User"; age = 25; email = Some "user@example.com" } in
  let json = Json_utils.person_to_json person in
  printf "Person as JSON: %s\n" (Yojson.Basic.pretty_to_string json);
  
  printf "=== CLI Complete ===\n"