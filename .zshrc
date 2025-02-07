export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

. "$HOME/.asdf/asdf.sh"
# Remove the bash completion and use only the zsh one
fpath=(${ASDF_DIR}/completions $fpath)

autoload -Uz compinit && compinit 