#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "RIDEOS AI - PHASE 6.10 RESUME"
echo "=========================================================="

echo "Re-running blocked checks..."
bash scripts/phase6_10_release_runner.sh

echo "Evaluating STATUS..."
cat artifacts/phase6_10/STATUS.md

echo "Please check the evidence folder: artifacts/phase6_10/"
echo "Update STATUS.md based on new findings."
