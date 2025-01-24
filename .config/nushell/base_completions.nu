def latest [] {
    git add . 
    git commit -m "latest" 
    git push
}

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | from tsv --flexible --noheaders --no-infer
    | rename value description
}

# This completer will use carapace by default
let external_completer = {|spans|
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get -i 0.expansion

    let spans = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans.0 {
        # carapace completions are incorrect for nu
        nu => $fish_completer
        # fish completes commits and branch names in a nicer way
        git => $fish_completer
        # fish has better completions for nix
        nix => $fish_completer
        # fish has better completions for wg-quick
        wg-quick => $fish_completer
        # fish has better completions for wg
        wg => $fish_completer
        # fish has better completions for systemctl
        systemctl => $fish_completer
        # fish has better completions for xdg-mime
        xdg-mime => $fish_completer
        # fish has better completions for objdump
        objdump => $fish_completer
        # fish has better completions for zig
        zig => $fish_completer
        # fish has better completions for pkg-config
        pkg-config => $fish_completer
        # fish has better completions for meson
        meson => $fish_completer
        # fish has better completions for gtkwave
        gtkwave => $fish_completer
        # fish has better completions for networkctl
        networkctl => $fish_completer
        # fish has better completions for pandoc
        pandoc => $fish_completer
        # fish has better completions for uv
        uv => $fish_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config = {
    # ...
    completions: {
        external: {
            enable: true
            completer: $external_completer
        }
    }
    # ...
}
