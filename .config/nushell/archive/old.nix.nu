
# AUTHOR: Conner Ohnesorge
# nix flake show --impure --json --quiet | from json
# Output:
# ╭────────────┬──────────────────────────────────────────────────────────────────────────────────╮
# │            │ ╭──────┬─────────╮                                                               │
# │ containers │ │ type │ unknown │                                                               │
# │            │ ╰──────┴─────────╯                                                               │
# │            │ ╭────────────────┬─────────────────────────────────────────────────────────────╮ │
# │ packages   │ │                │ ╭──────┬───────────────────╮                                │ │
# │            │ │ aarch64-darwin │ │ api  │ {record 0 fields} │                                │ │
# │            │ │                │ │ docs │ {record 0 fields} │                                │ │
# │            │ │                │ │ web  │ {record 0 fields} │                                │ │
# │            │ │                │ ╰──────┴───────────────────╯                                │ │
# │            │ │                │ ╭──────┬───────────────────╮                                │ │
# │            │ │ aarch64-linux  │ │ api  │ {record 0 fields} │                                │ │
# │            │ │                │ │ docs │ {record 0 fields} │                                │ │
# │            │ │                │ │ web  │ {record 0 fields} │                                │ │
# │            │ │                │ ╰──────┴───────────────────╯                                │ │
# │            │ │                │ ╭──────┬───────────────────╮                                │ │
# │            │ │ x86_64-darwin  │ │ api  │ {record 0 fields} │                                │ │
# │            │ │                │ │ docs │ {record 0 fields} │                                │ │
# │            │ │                │ │ web  │ {record 0 fields} │                                │ │
# │            │ │                │ ╰──────┴───────────────────╯                                │ │
# │            │ │                │ ╭──────┬──────────────────────────────────────────────────╮ │ │
# │            │ │ x86_64-linux   │ │      │ ╭─────────────┬────────────╮                     │ │ │
# │            │ │                │ │ api  │ │ description │ API server │                     │ │ │
# │            │ │                │ │      │ │ name        │ api-0.1.0  │                     │ │ │
# │            │ │                │ │      │ │ type        │ derivation │                     │ │ │
# │            │ │                │ │      │ ╰─────────────┴────────────╯                     │ │ │
# │            │ │                │ │      │ ╭─────────────┬────────────────────────────────╮ │ │ │
# │            │ │                │ │ docs │ │ description │ API and Platform Documentation │ │ │ │
# │            │ │                │ │      │ │ name        │ docs-0.1.0                     │ │ │ │
# │            │ │                │ │      │ │ type        │ derivation                     │ │ │ │
# │            │ │                │ │      │ ╰─────────────┴────────────────────────────────╯ │ │ │
# │            │ │                │ │      │ ╭─────────────┬────────────╮                     │ │ │
# │            │ │                │ │ web  │ │ description │ Web UI     │                     │ │ │
# │            │ │                │ │      │ │ name        │ web-0.1.0  │                     │ │ │
# │            │ │                │ │      │ │ type        │ derivation │                     │ │ │
# │            │ │                │ │      │ ╰─────────────┴────────────╯                     │ │ │
# │            │ │                │ ╰──────┴──────────────────────────────────────────────────╯ │ │
# │            │ ╰────────────────┴─────────────────────────────────────────────────────────────╯ │
# ╰────────────┴──────────────────────────────────────────────────────────────────────────────────╯
#
#
# Suggested completions for 'nix build .#<TAB>':
#
#   packages.aarch64-darwin.api
#   packages.aarch64-linux.api
#   packages.x86_64-darwin.api
#   packages.x86_64-linux.api
#   packages.aarch64-darwin.docs
#   packages.aarch64-linux.docs
#   packages.x86_64-darwin.docs
#   packages.x86_64-linux.docs
#   packages.aarch64-darwin.web
#   packages.aarch64-linux.web
#   packages.x86_64-darwin.web
#   packages.x86_64-linux.web



let systems = nix flake show --impure --json --quiet --all-systems | from json 

let targets = [
    "packages",
    "containers",
    "devShells",
    "apps",
    "checks",
]

let allCompletions = $targets
| each {
    |target|
    let intersystems = $systems | get -i $target
    let transystems = $intersystems | transpose
    let transystemsLen = $transystems | length
    if $transystemsLen == 0 {
        null
    }
    let outie = $transystems | enumerate | each {
        |elt| $elt.item | get column1 | transpose | get column0 | each { |sub|
                    {
                        value: $"packages.($elt.item | get column0).($sub)",
                        description: $"packages.($elt.item | get column0).($sub)",
                        style: green
                    }
        }
    }
    $outie
}
print $allCompletions

let transystems = $systems | get "packages" | transpose
# let ess = $transystems | enumerate | 
#     each {
#             |elt| 
#             let subsid = $elt.item | get column1 | transpose | get column0
#             $subsid | each {
#                     |sub| print $sub
#                     $"packages.($elt.item | get column0).($sub)" 
#             }
#     }
let outie = $transystems | enumerate | each {
    |elt| $elt.item | get column1 | transpose | get column0 | each { |sub| 
                {
                    value: $"packages.($elt.item | get column0).($sub)",
                    description: $"packages.($elt.item | get column0).($sub)",
                    style: green
                }
    }
}
let completions = $outie | flatten 

module nixb {
    def build-targets [] {
        $completions
    }

    export def build [animal: string@build-targets] {
        nix build $".#($animal)"
    }
}

use nixb
print "used nixb"
