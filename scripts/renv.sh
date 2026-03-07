#!/usr/bin/env bash
# Source this file to configure the R environment for rsparrow development:
#   source scripts/renv.sh
#
# Sets:
#   R_LIBS                     — path to installed R packages
#   _R_CHECK_FORCE_SUGGESTS_   — allows R CMD check without all Suggests installed

export R_LIBS=/home/kp/R/libs
export _R_CHECK_FORCE_SUGGESTS_=false

echo "R environment configured:"
echo "  R_LIBS=$R_LIBS"
echo "  _R_CHECK_FORCE_SUGGESTS_=$_R_CHECK_FORCE_SUGGESTS_"
