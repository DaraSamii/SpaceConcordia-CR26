#!/bin/bash
#SBATCH --job-name=CR26
#SBATCH --mem=400G
#SBATCH --nodes=1
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
#SBATCH --time=15:0:0    
#SBATCH --mail-user=darasamii@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-tembelym
#SBATCH --output=submit.log


./Mesh.sh
./Allrun.sh

