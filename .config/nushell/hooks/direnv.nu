{ ||
    if (which direnv | is-empty) {
        return
    }
    

    # watch . --glob=$"($REPO_ROOT)/devenv.nix" { || 
    #     direnv export json | from json | default {} | load-env
    # }
    # try {
    # } catch {
    #     print 'divided by zero'
    # }
    direnv export json | from json | default {} | load-env
}
