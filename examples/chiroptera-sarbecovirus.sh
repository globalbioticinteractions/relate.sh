#!/bin/bash
#
# Example script using relate.sh in context.
#
# Please use with care, this script is not fully tested,
# and has undocumented requirements and dependencies.
#
# Script takes a snapshot of GloBI uninterpreted index,
# links their names to dynamically generated taxonomies, 
# then exports them to interactions.tsv.gz files. 
#

function get_names {
  curl https://zenodo.org/record/5719410/files/names.tsv.gz > names.tsv.gz
}

function relate_names {

 time cat names.tsv.gz\
  | gunzip\
  | pv -l\
  | ./relate.sh gbif\
  | grep "GBIF:734[ \t]"\
  | tee names_chiroptera_gbif_734.tsv

  time cat names.tsv.gz\
   | gunzip\
   | pv -l\
   | ./relate.sh itis\
   | grep "ITIS:179985[ \t]"\
   | tee names_chiroptera_itis_179985.tsv

  time cat names.tsv.gz\
   | gunzip\
   | pv -l\
   | ./relate.sh ncbi\
   | grep "NCBI:9397[ \t]"\
   | tee names_chiroptera_ncbi_9397.tsv

  time cat names.tsv.gz\
   | gunzip\
   | pv -l\
   | ./relate.sh ncbi\
   | grep "NCBI:2509511[ \t]"\
   | tee names_sarbeco_ncbi_2509511.tsv
}

function create_taxon_graph {

  GRAPH_DIR=$1_$2
  mkdir -p $GRAPH_DIR

  cat names_$1.tsv\
   | cut -f1,2,4,5\
   | sort\
   | uniq\
   | gzip\
   > $GRAPH_DIR/taxonMap.tsv.gz

  cat names_$1.tsv\
   | cut -f4-\
   | sort\
   | uniq\
   | gzip\
   > $GRAPH_DIR/taxonCache.tsv.gz

  cat names_$2.tsv\
   | cut -f1,2,4,5\
   | sort\
   | uniq\
   | gzip\
   >> $GRAPH_DIR/taxonMap.tsv.gz

  cat names_$2.tsv\
   | cut -f4-\
   | sort\
   | uniq\
   | gzip\
   >> $GRAPH_DIR/taxonCache.tsv.gz

}

function interpret_interaction_data {
  rm -rf graph.db
  rm -rf target

  GRAPHDB_DIR=$PWD/graph.db
  rm -rf $GRAPHDB_DIR
  unzip /var/cache/globi/repository/org/eol/eol-globi-datasets/1.1-SNAPSHOT/eol-globi-datasets-1.1-SNAPSHOT-neo4j-compiled.zip

  EXPORT_DIR=$PWD/$1_$2/export
  mkdir -p $EXPORT_DIR

  ELTON4N_HOME=/home/jhpoelen/eol-globi-data/elton4n/target

  create_taxon_graph $1 $2

  java -classpath $ELTON4N_HOME/elton4n-0.23.3-SNAPSHOT.jar:$ELTON4N_HOME/lib/*\
   org.globalbioticinteractions.elton.Elton4N\
   -graphDbDir $GRAPHDB_DIR\
   -taxonCache file://$PWD/$1_$2/taxonCache.tsv.gz\
   -taxonMap file://$PWD/$1_$2/taxonMap.tsv.gz\
   -exportDir $EXPORT_DIR\
   link-names\
   package-interactions-tsv

}

function filter_interaction_data {
   cat sarbeco_ncbi_2509511_chiroptera_gbif_734/export/tsv/interactions.tsv.gz\
   | gunzip\
   | mlr --tsvlite filter '$targetTaxonOrderId == "GBIF:734" || $sourceTaxonOrderId == "GBIF:734"'\
   | mlr --tsvlite filter '$targetTaxonSubgenusId == "NCBI:2509511" || $sourceTaxonSubgenusId == "NCBI:2509511"'\
   > interactions_sarbeco_ncbi_2509511_chiroptera_gbif_734.tsv

   cat sarbeco_ncbi_2509511_chiroptera_itis_179985/export/tsv/interactions.tsv.gz\
   | gunzip\
   | mlr --tsvlite filter '$targetTaxonOrderId == "ITIS:179985" || $sourceTaxonOrderId == "ITIS:179985"'\
   | mlr --tsvlite filter '$targetTaxonSubgenusId == "NCBI:2509511" || $sourceTaxonSubgenusId == "NCBI:2509511"'\
   > interactions_sarbeco_ncbi_2509511_chiroptera_itis_179985.tsv

   cat sarbeco_ncbi_2509511_chiroptera_ncbi_9397/export/tsv/interactions.tsv.gz\
   | gunzip\
   | mlr --tsvlite filter '$targetTaxonOrderId == "NCBI:9397" || $sourceTaxonOrderId == "NCBI:9397"'\
   | mlr --tsvlite filter '$targetTaxonSubgenusId == "NCBI:2509511" || $sourceTaxonSubgenusId == "NCBI:2509511"'\
   > interactions_sarbeco_ncbi_2509511_chiroptera_ncbi_9397.tsv

}

get_names

relate_names

interpret_interaction_data sarbeco_ncbi_2509511 chiroptera_itis_179985
interpret_interaction_data sarbeco_ncbi_2509511 chiroptera_gbif_734
interpret_interaction_data sarbeco_ncbi_2509511 chiroptera_ncbi_9397

filter_interaction_data
