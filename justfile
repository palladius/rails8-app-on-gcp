# default recipe
default:
    @just --list

# show open issues via gh
status:
    gh issue list --state open
