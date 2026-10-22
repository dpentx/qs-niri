#!/usr/bin/env bash
# File manager copy / move:  fm-transfer.sh DEST CUT(0|1) (MODE SRC)...
# MODE "-" plain, "replace" (old one goes to the trash first), "both" (keep both: "name (2).ext").
# Copies: a file of 1 MiB or more goes through `pv`, a folder through `rsync`, both of which report real
# progress; anything else (or a missing pv / rsync) is a plain `cp -a`. A copy that runs longer than
# ~2 s shows a progress notification, replaced in place with a `value` hint (the shell draws a bar).
# Moves are renames (`mv`), so they get none.
# shortcut: a cross-disk move is one long mv with no bar; rsync does not preserve hard links (no -H).
d=$1 cut=$2; shift 2
src=() tgt=() size=() fail=0
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

total=0
if [ "$cut" != 1 ]; then
  while read -r sz _; do size+=("$sz"); total=$((total + sz)); done < <(du -sb -- "${src[@]}" 2>/dev/null)
  # du skips repeated hard links, so the counts can differ: weigh every item the same then
  [ ${#size[@]} = ${#src[@]} ] || { size=(); for _ in "${src[@]}"; do size+=(1); done; total=${#src[@]}; }
  [ $total -gt 0 ] || total=1
fi

start=$SECONDS id= last=-1
report() {  # $1 = bytes done so far
  [ $((SECONDS - start)) -ge "${FM_DELAY:-2}" ] && [ "$SECONDS" != "$last" ] || return 0
  last=$SECONDS
  local pct=$(( $1 * 100 / total )); [ $pct -gt 99 ] && pct=99
  local txt="$pct%  ·  $(numfmt --to=iec "$1") of $(numfmt --to=iec "$total")"
  if [ -z "$id" ]; then id=$(notify -p -t 0 -h int:value:$pct "Copying $label" "$txt")
  else notify -r "$id" -t 0 -h int:value:$pct "Copying $label" "$txt"; fi
}
last_pct() {  # $1 = r (rsync) | p (pv), $2 = its log
  if [ "$1" = r ]; then tr '\r' '\n' < "$2" | grep -o '[0-9]\+%' | tail -1 | tr -d %
  else tail -n1 "$2" | grep -x '[0-9]\+'; fi
}

done_b=0
for i in "${!src[@]}"; do
  s=${src[i]} t=${tgt[i]}
  if [ "$cut" = 1 ]; then mv -n -- "$s" "$t" || fail=1; continue; fi
  log=$(mktemp)
  if [ -d "$s" ] && [ ! -L "$s" ] && command -v rsync >/dev/null; then
    rsync -a --no-inc-recursive --info=progress2 -- "$s/" "$t/" > "$log" 2>&1 &
    kind=r
  elif [ -f "$s" ] && [ ! -L "$s" ] && [ "${size[i]}" -ge 1048576 ] && command -v pv >/dev/null; then
    # noclobber: never truncate a file that appeared since the conflict check; pv does not keep
    # mode / times, so they are copied over afterwards
    { set -C; pv -n -- "$s" > "$t" 2>| "$log" && cp -a --attributes-only -- "$s" "$t"; } &
    kind=p
  else
    cp -a -- "$s" "$t" || fail=1
    done_b=$((done_b + size[i])); rm -f "$log"; continue
  fi
  pid=$! tick=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 0.1
    [ $((++tick % 10)) = 0 ] || continue
    p=$(last_pct "$kind" "$log"); report $(( done_b + size[i] * ${p:-0} / 100 ))
  done
  wait "$pid" || { fail=1; [ "$kind" = p ] && rm -f -- "$t"; }
  done_b=$((done_b + size[i])); rm -f "$log"
done

if [ $fail = 1 ]; then notify -u critical ${id:+-r "$id"} "$noun failed" "$label"
elif [ -n "$id" ]; then notify -r "$id" "$noun finished" "$label"; fi
exit $fail
