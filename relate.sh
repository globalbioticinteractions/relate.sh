#!/bin/bash
# Relates provided names to resolved name using a Nomer [1] matcher
#
# Usage:
#   ./relate.sh [matcher]
#
#
# Example:
#   $ echo -e "NCBI:9696\tPuma concolor" | ./relate.sh ncbi
#   providedExternalId	providedName	relationName	resolvedExternalId	resolvedName	resolvedRank	resolvedCommonNames	resolvedPath	resolvedPathIds	resolvedPathNames	resolvedExternalUrl	resolvedThumbnailUrl
#   NCBI:9696	Puma concolor	SAME_AS	NCBI:9696	Puma concolor	species		root | cellular organisms | Eukaryota | Opisthokonta | Metazoa | Eumetazoa | Bilateria | Deuterostomia | Chordata | Craniata | Vertebrata | Gnathostomata | Teleostomi | Euteleostomi | Sarcopterygii | Dipnotetrapodomorpha | Tetrapoda | Amniota | Mammalia | Theria | Eutheria | Boreoeutheria | Laurasiatheria | Carnivora | Feliformia | Felidae | Felinae | Puma | Puma concolor	NCBI:1 | NCBI:131567 | NCBI:2759 | NCBI:33154 | NCBI:33208 | NCBI:6072 | NCBI:33213 | NCBI:33511 | NCBI:7711 | NCBI:89593 | NCBI:7742 | NCBI:7776 | NCBI:117570 | NCBI:117571 | NCBI:8287 | NCBI:1338369 | NCBI:32523 | NCBI:32524 | NCBI:40674 | NCBI:32525 | NCBI:9347 | NCBI:1437010 | NCBI:314145 | NCBI:33554 | NCBI:379583 | NCBI:9681 | NCBI:338152 | NCBI:146712 | NCBI:9696	|  | superkingdom | clade | kingdom | clade | clade | clade | phylum | subphylum | clade | clade | clade | clade | superclass | clade | clade | clade | class | clade | clade | clade | superorder | order | suborder | family | subfamily | genus | species	https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=9696	
#   
#
# References
#
# [1] Jorrit Poelen, & José Augusto Salim. (2021). globalbioticinteractions/nomer: (0.2.9). Zenodo. https://doi.org/10.5281/zenodo.5722620
#
#

MATCHER=${1:-itis}
NOMER_VERSION=0.2.9
NOMER_JAR=nomer.jar

if [[ $(which nomer) ]]
  then 
    echo using local nomer found at [$(which elton)]
    export NOMER_CMD="nomer"
  else
    local NOMER_DOWNLOAD_URL="https://github.com/globalbioticinteractions/nomer/releases/download/${NOMER_VERSION}/nomer.jar"
    echo nomer not found... installing from [${ELTON_DOWNLOAD_URL}]
    curl --silent -L "${NOMER_DOWNLOAD_URL}" > "${NOMER_JAR}"
    export NOMER_CMD="java -Xmx4G -jar ${NOMER_JAR}"
  fi

PROPS_FILE=$(tempfile)

echo 'nomer.schema.input=[{"column":3,"type":"externalId"},{"column": 4,"type":"name"}]'\
> $PROPS_FILE

MATCH_FIRST_PASS=$(tempfile)
MATCH_SECOND_PASS=$(tempfile)

TEMP_FILES="$MATCH_FIRST_PASS $MATCH_SECOND_PASS $PROPS_FILE"

cut -f1,2\
| $NOMER_CMD append --include-header $MATCHER\
> $MATCH_FIRST_PASS

cat $MATCH_FIRST_PASS\
| tail -n+2\
| grep NONE\
| cut -f1,2\
| $NOMER_CMD append globi-correct\
| $NOMER_CMD append --properties $PROPS_FILE $MATCHER\
> $MATCH_SECOND_PASS

head -1 $MATCH_FIRST_PASS

cat $MATCH_FIRST_PASS\
| tail -n+2\
| grep -v NONE

cat $MATCH_SECOND_PASS\
| cut -f1,2,13-

rm $TEMP_FILES


