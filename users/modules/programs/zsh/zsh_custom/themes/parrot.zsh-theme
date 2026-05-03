PROMPT='%F{red}┌─[%f%F{*}%*%f%F{red}]─[%f%F{yellow}%n%f%F{red}@%f%F{green}%m%f%F{red}]─[%f%F{cyan}%~%f%F{red}]%f
%F{red}└──╼%f%F{yellow}$%f '
RPROMPT='%F{red}[%f%F{blue}$(git_prompt_info 2>/dev/null || echo "")%f%F{red}]%f'

git_prompt_info() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local branch=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
      if git diff --quiet 2>/dev/null; then
        echo "%F{green}${branch}✓%f"
      else
        echo "%F{red}${branch}x%f"
      fi
    fi
  fi
}