# Put user-local bin dirs on PATH once (idempotent across re-sourcing).
for _d in "$HOME/.local/bin" "$HOME/bin"; do
    case ":$PATH:" in
        *":$_d:"*) ;;
        *) [ -d "$_d" ] && PATH="$_d:$PATH" ;;
    esac
done
unset _d
export PATH
