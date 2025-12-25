#!/bin/bash
#SBATCH --job-name=TwoM1p2A3p0
#SBATCH --mem=400G
#SBATCH --nodes=1
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
#SBATCH --time=15:0:0    
#SBATCH --mail-user=darasamii@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-tembelym
#SBATCH --output=submit.log


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


