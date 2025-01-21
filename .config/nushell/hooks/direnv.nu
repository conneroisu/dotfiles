{ ||
    if (which direnv | is-empty) {
        return
    }

    direnv export json | from json | default {} | load-env
}
