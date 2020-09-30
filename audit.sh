#!/bin/bash
############################################################
## Script run all static audit steps for the projects
## Created to ease usage in the GH CI actions
## System dependencies: "jq"
## Python dependencies: Content of the "requirements.txt"
############################################################
cdir=$(pwd)
echo "Run unit test suites..."
pytest
echo "RC: $?"
echo "Extract flake8, pydocstyle and bandit configuration from VSCode workspace file..."
flake8Args=$(cat project.code-workspace | jq -r '.settings["python.linting.flake8Args"]|join(" ")')
pydocstyleArgs=$(cat project.code-workspace | jq -r '.settings["python.linting.pydocstyleArgs"]|join(" ")')
banditArgs=$(cat project.code-workspace | jq -r '.settings["python.linting.banditArgs"]|join(" ")')
echo "Run flake8..."
python -m flake8 $flake8Args $cdir
echo "RC: $?"
echo "Run pydocstyle..."
python -m pydocstyle $pydocstyleArgs $cdir
echo "RC: $?"
echo "Run bandit..."
bandit $banditArgs -r $cdir
echo "RC: $?"