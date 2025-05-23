# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# ZSH plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
alias dc="docker-compose"
alias gd="git diff"
alias gcoman="git commit --amend --no-edit"
alias gco="git checkout"
alias gpnb='git push -u origin $(git symbolic-ref --short HEAD)'
alias gpn='gpnb'
alias p="pnpm"
alias lsa="ls -a"
alias gci='GIT_EDITOR=true git commit'
alias gcia='GIT_EDITOR=true git commit -a'
alias lg="lazygit"

# aliases for quicker opening of code and cursor
alias cu="open $1 -a \"Cursor\""
alias co="open $1 -a \"Visual Studio Code\""

grecent() {
  printf "%-30s %s\n" "BRANCH" "LAST COMMIT"
  printf "%-30s %s\n" "$(printf '=%.0s' {1..30})" "$(printf '=%.0s' {1..25})"
  
  # Get branch info and format as table
  git for-each-ref \
    --sort=-committerdate \
    refs/heads/ \
    --format="%(refname:short)|%(committerdate:format:%Y-%m-%d %H:%M:%S)" \
    | head -n 10 \
    | while IFS='|' read -r branch date; do
        printf "%-30s %s\n" "$branch" "$date"
    done
}

gcma() {
  git checkout main &&
  git pull -r &&
  p i
}

grm() {
  local current_branch=$(git symbolic-ref --short HEAD)
  git checkout main &&
  git pull origin main &&
  git checkout "$current_branch" &&
  git rebase main
}

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt share_history        # share history between sessions
setopt extended_history     # add timestamps to history
setopt hist_expire_dups_first
setopt hist_ignore_dups     # ignore duplicated commands
setopt hist_ignore_space    # ignore commands that start with space
setopt hist_verify          # show command before executing history substitution

# Enable completion system
autoload -Uz compinit
compinit

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun completions
[ -s "/Users/alex/.bun/_bun" ] && source "/Users/alex/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# golang
export PATH="$(go env GOPATH)/bin:$PATH"

# nvmrc
source $HOME/.nvm/nvm.sh


# pnpm
export PNPM_HOME="/Users/alex/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/Users/alex/.opencode/bin:$PATH

# pdm
export PATH=/Users/alex/Library/Python/3.9/bin:$PATH

# Starship
eval "$(starship init zsh)"
