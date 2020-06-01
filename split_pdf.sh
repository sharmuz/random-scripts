#!/bin/bash
for pdf_file in ./pdf_dataset/**/*.pdf
do
    FILENAME="$pdf_file"
    FILESIZE=$(stat -c%s "$FILENAME")
    if [ $FILESIZE -gt 1000000 ]
    then
        gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -q -o "$FILENAME.tmp" $FILENAME
        rm $FILENAME
        qpdf --object-streams=generate --split-pages=5 "$FILENAME.tmp" ${FILENAME%.pdf}_%d.pdf
        rm "$FILENAME.tmp"
    fi
done
