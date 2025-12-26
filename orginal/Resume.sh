#!/bin/bash
#SBATCH --job-name=CR26
#SBATCH --mem=400G
#SBATCH --nodes=1
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
#SBATCH --time=20:0:0    
#SBATCH --mail-user=darasamii@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-tembelym
#SBATCH --output=submitResume.log


cd "$(dirname "$0")" || exit 1
echo "Running in: $(pwd)"


latest=$(find processors* -maxdepth 1 -type d -regex '.*/[0-9]+' | \
         sed 's|.*/||' | sort -n -u | tail -1)

# Only delete if latest is NOT 0
if [ "$latest" != "0" ]; then
    rm -rf processors*/"$latest"
    echo "Deleted processors*/$latest"
else
    echo "Latest time is 0 or not found, nothing deleted"
fi

#----------------------------------------
# Load OpenFOAM v2406 Environment
#----------------------------------------
echo "Loading OpenFOAM v2406 environment..."

module purge
source ~/OpenFOAM/v2412/OpenFOAM-v2412/etc/bashrc
numProcs=$SLURM_NTASKS
echo "OpenFOAM v2406 loaded via module with $numProcs processors."


echo "Running rhoSimpleFoam in parallel..."
mpirun -np $numProcs rhoSimpleFoam -fileHandler collated -parallel

#----------------------------------------
# Step 11: Reconstruct results
echo "Reconstructing latest time..."
reconstructPar -latestTime
#----------------------------------------
# Step 12: Post-process
echo "Sampling rocket patch to VTK..."
postProcess -func rocketVTK -latestTime


