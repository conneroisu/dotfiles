open Base
open Stdio
open Ocaml_template

(** Simple examples demonstrating the library functionality *)

let () =
  printf "=== OCaml Template Examples ===\n\n";
  
  (* Basic greeting *)
  printf "1. Basic Greetings:\n";
  printf "   %s\n" (greet "Alice");
  printf "   %s\n" (greet ~greeting:"Bonjour" "Bob");
  printf "\n";
  
  (* Math examples *)
  printf "2. Math Functions:\n";
  printf "   Fibonacci sequence (first 10): ";
  List.range 0 10 
  |> List.map ~f:Math.fibonacci 
  |> List.map ~f:Int.to_string
  |> String.concat ~sep:", "
  |> printf "%s\n";
  
  printf "   Prime numbers up to 50: ";
  Math.primes_up_to 50
  |> List.map ~f:Int.to_string
  |> String.concat ~sep:", "
  |> printf "%s\n";
  printf "\n";
  
  (* JSON handling *)
  printf "3. JSON Handling:\n";
  let people = [
    Json_utils.{ name = "Alice"; age = 25; email = Some "alice@example.com" };
    Json_utils.{ name = "Bob"; age = 30; email = None };
    Json_utils.{ name = "Charlie"; age = 35; email = Some "charlie@test.org" };
  ] in
  
  people |> List.iter ~f:(fun person ->
    let json = Json_utils.person_to_json person in
    printf "   %s\n" (Yojson.Basic.pretty_to_string json)
  );
  printf "\n";
  
  (* Logging *)
  printf "4. Logging Example:\n";
  Logger.setup_logging (Some Logs.Info);
  Logger.info "This is an info message";
  Logger.warn "This is a warning";
  Logger.debug "This debug message won't show (log level is Info)";
  printf "\n";
  
  printf "=== Examples Complete ===\n"