open Base
open Ocaml_template

(** Alcotest unit tests *)
module Unit_tests = struct
  let test_greet () =
    Alcotest.(check string) "default greeting" "Hello, World!" (greet "world");
    Alcotest.(check string) "custom greeting" "Hi, Alice!" (greet ~greeting:"Hi" "alice")

  let test_fibonacci () =
    Alcotest.(check int) "fib(0)" 0 (Math.fibonacci 0);
    Alcotest.(check int) "fib(1)" 1 (Math.fibonacci 1);
    Alcotest.(check int) "fib(5)" 5 (Math.fibonacci 5);
    Alcotest.(check int) "fib(10)" 55 (Math.fibonacci 10)

  let test_is_prime () =
    Alcotest.(check bool) "2 is prime" true (Math.is_prime 2);
    Alcotest.(check bool) "3 is prime" true (Math.is_prime 3);
    Alcotest.(check bool) "4 is not prime" false (Math.is_prime 4);
    Alcotest.(check bool) "17 is prime" true (Math.is_prime 17)

  let test_primes_up_to () =
    let expected = [2; 3; 5; 7] in
    Alcotest.(check (list int)) "primes up to 10" expected (Math.primes_up_to 10)

  let test_json_roundtrip () =
    let person = Json_utils.{ name = "Alice"; age = 30; email = Some "alice@example.com" } in
    let json = Json_utils.person_to_json person in
    let person' = Json_utils.person_from_json json in
    Alcotest.(check string) "name preserved" person.name person'.name;
    Alcotest.(check int) "age preserved" person.age person'.age;
    Alcotest.(check (option string)) "email preserved" person.email person'.email
end

(** QCheck property-based tests *)
module Property_tests = struct
  open QCheck

  let test_greet_not_empty =
    Test.make ~count:100 ~name:"greet never returns empty string"
      (string_of_size Gen.(1 -- 20))
      (fun name -> String.length (greet name) > 0)

  let test_fibonacci_monotonic =
    Test.make ~count:50 ~name:"fibonacci is monotonic for small values"
      Gen.(0 -- 20)
      (fun n -> 
        if n = 0 then true
        else Math.fibonacci n >= Math.fibonacci (n - 1))

  let test_prime_properties =
    Test.make ~count:100 ~name:"prime numbers > 2 are odd"
      Gen.(2 -- 100)
      (fun n ->
        if Math.is_prime n && n > 2 then n % 2 = 1
        else true)

  let test_json_roundtrip =
    Test.make ~count:100 ~name:"JSON person roundtrip"
      Gen.(triple (string_of_size (1 -- 20)) (0 -- 120) bool)
      (fun (name, age, has_email) ->
        let email = if has_email then Some (name ^ "@example.com") else None in
        let person = Json_utils.{ name; age; email } in
        let json = Json_utils.person_to_json person in
        try
          let person' = Json_utils.person_from_json json in
          String.equal person.name person'.name && 
          Int.equal person.age person'.age &&
          Option.equal String.equal person.email person'.email
        with
        | _ -> false)

  let all_property_tests = [
    test_greet_not_empty;
    test_fibonacci_monotonic;
    test_prime_properties;
    test_json_roundtrip;
  ]
end

(** Async tests using Lwt *)
module Async_tests = struct
  let test_async_greet () =
    let open Lwt.Syntax in
    let* result = Async_utils.async_greet ~delay:0.1 "async" in
    Alcotest.(check string) "async greeting" "Hello, Async!" result;
    Lwt.return ()

  let test_with_timeout () =
    let open Lwt.Syntax in
    (* This should complete within timeout *)
    let* result = Async_utils.with_timeout ~timeout:1.0 (fun () ->
      Async_utils.async_greet ~delay:0.1 "quick"
    ) in
    Alcotest.(check string) "quick operation" "Hello, Quick!" result;
    
    (* This should timeout *)
    let* () = 
      Lwt.catch
        (fun () ->
          let* _ = Async_utils.with_timeout ~timeout:0.1 (fun () ->
            Async_utils.async_greet ~delay:1.0 "slow"
          ) in
          Lwt.fail_with "Should have timed out"
        )
        (function
          | Failure "Operation timed out" -> Lwt.return ()
          | e -> Lwt.fail e)
    in
    Lwt.return ()
end

(** Run all tests *)
let () =
  (* Run Alcotest unit tests *)
  let unit_tests = [
    "greet", [
      Alcotest.test_case "basic greeting" `Quick Unit_tests.test_greet;
    ];
    "math", [
      Alcotest.test_case "fibonacci" `Quick Unit_tests.test_fibonacci;
      Alcotest.test_case "is_prime" `Quick Unit_tests.test_is_prime;
      Alcotest.test_case "primes_up_to" `Quick Unit_tests.test_primes_up_to;
    ];
    "json", [
      Alcotest.test_case "roundtrip" `Quick Unit_tests.test_json_roundtrip;
    ];
    (* "async", [
      Alcotest_lwt.test_case "async_greet" `Quick (fun _ () -> Async_tests.test_async_greet ());
      Alcotest_lwt.test_case "timeout" `Quick (fun _ () -> Async_tests.test_with_timeout ());
    ]; *)
  ] in
  
  Alcotest.run "OCaml Template Tests" unit_tests;
  
  (* Run QCheck property-based tests *)
  Printf.printf "\n=== Property-based Tests ===\n";
  QCheck_runner.run_tests Property_tests.all_property_tests |> ignore