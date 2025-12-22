#!/bin/bash

# ============================
# OpenFOAM v2406 Automation Script
# blockMesh → snappy → reconstruct → topoSet → run
# ============================


cd "$(dirname "$0")" || exit 1
echo "Running in: $(pwd)"


#----------------------------------------
# Load OpenFOAM v2406 Environment
#----------------------------------------
echo "Loading OpenFOAM v2406 environment..."
if module avail openfoam/v2406 &>/dev/null; then
    module purge
    source ~/OpenFOAM/v2412/OpenFOAM-v2412/etc/bashrc
    numProcs=$SLURM_NTASKS
    echo "OpenFOAM v2406 loaded via module with $numProcs processors."
else
    source /opt/openfoam2406/etc/bashrc
    numProcs=8
    echo "OpenFOAM v2406 loaded from /opt with $numProcs processors."
fi

#----------------------------------------
# Clean Case
#----------------------------------------
echo "Cleaning case..."
rm -rf 0 processor*
cp -r 0.orig 0

mkdir -p logs
touch foam.foam

#----------------------------------------
# Step 6: Renumber
echo "Renumbering mesh..."
renumberMesh -overwrite > logs/renumberMesh.log 2>&1

#----------------------------------------
# Step 7: Decompose final mesh
echo "Decomposing final mesh..."
subdiv_x=$((numProcs / 4))
foamDictionary system/decomposeParDict -entry "numberOfSubdomains" -set "$numProcs"
foamDictionary system/decomposeParDict -entry "n" -set "($subdiv_x 2 2)"
decomposePar -fileHandler collated > logs/decomposePar.log 2>&1

#----------------------------------------

#----------------------------------------
# Step 9: foam.foam for ParaView
echo "Creating foam.foam..."
for d in processor*; do touch "$d/foam.foam"; done


#----------------------------------------
cp ./system/fvSchemes.stable ./system/fvSchemes 
#----------------------------------------


echo "Running rhoSimpleFoam in parallel..."
mpirun -np $numProcs rhoSimpleFoam -fileHandler collated -parallel > logs/rhoSimpleFoam.log 2>&1

#----------------------------------------
# Step 11: Reconstruct results
echo "Reconstructing latest time..."
reconstructPar -latestTime > logs/reconstructPar.log 2>&1

#----------------------------------------
# Step 12: Post-process
echo "Sampling rocket patch to VTK..."
postProcess -func rocketVTK -latestTime > logs/rocketVTK.log 2>&1

