#!/bin/bash

# In St. Lawrence Island Yupik, a voiced consonant can't be next to a voiceless one.

# Voiced Continuants (Fricatives, Laterals, Nasals): g, gh, l, r, v, z, w, m, n, ng, (ghw, ngw)
# Voiceless Continuants (Fricatives, Laterals, Nasals): gg, ghh, ll, rr, f, s, (wh), mm, nn, ngng, (ghhw, ngngw)
# Voiceless Stops (which often cause the change): p, t, k, q

PAIRS=(
    # g -> gg
    "gt:ggt"
    "gk:ggk"
    "gq:ggq"
    "gs:ggs"
    "gp:ggp"
    "gf:ggf"

    # gg -> g
    "gga:ga"
    "ggi:gi"
    "ggu:gu"
    "gge:ge"

    # ghh -> gh
    "ghha:gha"
    "ghhi:ghi"
    "ghhu:ghu"
    "ghhe:ghe"

    # gh -> ghh
    "ght:ghht"
    "ghk:ghhk"
    "ghq:ghhq"
    "ghs:ghhs"
    "ghp:ghhp"
    "ghf:ghhf"

    # l -> ll; Pick up work here
    "lt:llt"
    "lk:llk"
    "lq:llq"
    "ls:lls"
    "lp:llp"
    "lf:llf"

    # r -> rr
    "rt:rrt"
    "rk:rrk"
    "rq:rrq"
    "rs:rrs"
    "rp:rrp"
    "rf:rrf"

    # v -> f
    "vt:ft"
    "vk:fk"
    "vq:fq"
    "vs:fs"
    "vp:fp"
    "vf:ff"

    # z -> s
    "zt:st"
    "zk:sk"
    "zq:sq"
    "zs:ss"
    "zp:sp"
    "zf:sf"

    # w -> wh
    "wt:wht"
    "wk:whk"
    "wq:whq"
    "ws:whs"
    "wp:whp"
    "wf:whf"

    # m -> mm
    "mt:mmt"
    "mk:mmk"
    "mq:mmq"
    "ms:mms"
    "mp:mmp"
    "mf:mmf"

    # n -> nn
    "nt:nnt"
    "nk:nnk"
    "nq:nnq"
    "ns:nns"
    "np:nnp"
    "nf:nnf"

    # ng -> ngng
    "ngt:ngngt"
    "ngk:ngngk"
    "ngq:ngngq"
    "ngs:ngngs"
    "ngp:ngngp"
    "ngf:ngngf"

    # ghw -> ghhw
    "ghwt:ghhwt"
    "ghwk:ghhwk"
    "ghwq:ghhwq"
    "ghws:ghhws"
    "ghwp:ghhwp"
    "ghwf:ghhwf"

    # ngw -> ngngw
    "ngwt:ngngwt"
    "ngwk:ngngwk"
    "ngwq:ngngwq"
    "ngws:ngngws"
    "ngwp:ngngwp"
    "ngwf:ngngwf"
)
#

findReplaceFile="./Find-and-Replace.sh"

# Check for input file
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 'inputFile'"
    echo "This script will modify the inputFile in-place."
    exit 1
fi

inputFile="$1"

if [ ! -f "$inputFile" ]; then
    echo "Error: Input file not found: $inputFile"
    exit 1
fi

if [ ! -x "$findReplaceFile" ]; then
    echo "Error: $findReplaceFile npt found."
    echo "Make sure it\'s in the correct folder with correct permissions.."
    exit 1
fi

echo "Applying Yupik voicing rules to $inputFile..."

# Loop through all pairs
for rule in "${PAIRS[@]}"; do
    # Split the rule string "search:replace"
    searchStr=$(echo "$rule" | cut -d':' -f1)
    replaceStr=$(echo "$rule" | cut -d':' -f2)

    if [ -n "$searchStr" ] && [ -n "$replaceStr" ]; then
        echo "Replacing '$searchStr' with '$replaceStr'..."
        "$findReplaceFile" "$searchStr" "$replaceStr" "$inputFile"
    fi
done

echo "Done. $inputFile has been updated."
exit 0
