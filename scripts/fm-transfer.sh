#!/usr/bin/env bash
# File manager copy / move:  fm-transfer.sh DEST CUT(0|1) (MODE SRC)...
# MODE "-" plain, "replace" (old one goes to the trash first), "both" (keep both: "name (2).ext").
# A copy that runs longer than ~2 s shows a progress notification, replaced in place with a `value`
# hint (the shell draws it as a bar). Moves are renames, so they get none.
# shortcut: progress is the size of the targets vs. the sources (du), so it is approximate; a cross-disk
# move is one long mv with no bar.
d=$1 cut=$2; shift 2
src=() tgt=() fail=0
while [ $# -gt 1 ]; do
  m=$1 s=$2; shift 2
  n=${s##*/} t=$d/$n
  case $m in
    replace) gio trash -- "$t" 2>/dev/null || rm -rf -- "$t" || { fail=1; continue; } ;;
    both) b=$n e=
          if [ ! -d "$s" ] && [[ $n == ?*.* ]]; then b=${n%.*} e=.${n##*.}; fi
          i=2; while [ -e "$d/$b ($i)$e" ]; do i=$((i+1)); done
          t="$d/$b ($i)$e" ;;
  esac
  src+=("$s") tgt+=("$t")
done
[ ${#src[@]} -gt 0 ] || exit 0

notify() { notify-send -a "File manager" "$@"; }
label="${#src[@]} items"; [ ${#src[@]} = 1 ] && label=${src[0]##*/}
noun=Copy; [ "$cut" = 1 ] && noun=Move

mon= idf=
if [ "$cut" != 1 ]; then
  total=$(du -scb -- "${src[@]}" 2>/dev/null | tail -1 | cut -f1)
  idf=$(mktemp)
  (
    sleep "${FM_DELAY:-2}"
    id=$(notify -p -t 0 -h int:value:0 "Copying $label" "to ${d##*/}") || exit
    echo "$id" > "$idf"
    while sleep 1; do
      cur=$(du -scb -- "${tgt[@]}" 2>/dev/null | tail -1 | cut -f1)
      pct=$(( ${total:-0} > 0 ? ${cur:-0} * 100 / total : 0 )); [ $pct -gt 99 ] && pct=99
      notify -r "$id" -t 0 -h int:value:$pct "Copying $label" "$pct%  ·  $(numfmt --to=iec "${cur:-0}") of $(numfmt --to=iec "${total:-0}")"
    done
  ) &
  mon=$!
fi

for i in "${!src[@]}"; do
  if [ "$cut" = 1 ]; then mv -n -- "${src[i]}" "${tgt[i]}" || fail=1
  else cp -a -- "${src[i]}" "${tgt[i]}" || fail=1; fi
done

id=
if [ -n "$mon" ]; then
  kill "$mon" 2>/dev/null; wait "$mon" 2>/dev/null
  id=$(cat "$idf" 2>/dev/null); rm -f "$idf"
fi
if [ $fail = 1 ]; then notify -u critical ${id:+-r "$id"} "$noun failed" "$label"
elif [ -n "$id" ]; then notify -r "$id" "$noun finished" "$label"; fi
exit $fail
