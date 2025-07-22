let test_hello () =
  Alcotest.(check string) "same string" "Hello, World!" (My_project.hello "World")

let () =
  let open Alcotest in
  run "My_project" [
    "hello", [ test_case "Hello function" `Quick test_hello ];
  ]
