~/bin/gvm 1.19 | source

set -gx PATH $PATH ~/.local/bin
set -gx PATH $PATH ~/go/bin
set -gx GPG_TTY (tty)

jump shell fish | source

alias vim="lvim"
alias pbcopy="xclip -selection clipboard"
alias pbpaste="xclip -selection clipboard -o"

starship init fish | source

