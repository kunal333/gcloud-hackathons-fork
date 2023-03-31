#!/bin/bash
set -e
TARGET=dist

mkdir -p ${TARGET}/hacks
rsync -av --exclude=${TARGET} --exclude=_site --exclude=tools --exclude=hacks --exclude=.git . ${TARGET}

NOTE="\\1> <span class=\"info\">{% octicon info %} Note</span>\\2"
WARN="\\1> <span class=\"alert\">{% octicon alert %} Warning</span>\\2"
for FAQ in $(ls $TARGET/faq/*.md); do
    sed -i -r \
        -e "s|(\s*)> \*\*Note\*\*(.*)|$NOTE|g" \
        -e "s|(\s*)> \*\*Warning\*\*(.*)|$WARN|g" \
        $1
done

for HACK in $(ls hacks); do
    GEN=${TARGET}/hacks/${HACK}
    IMG=hacks/${HACK}/images
    mkdir -p ${GEN}
    [ -d $IMG ] && cp -R ${IMG} ${GEN}/images
    python3 tools/split.py --output-dir ${GEN} hacks/${HACK}/README.md
done

