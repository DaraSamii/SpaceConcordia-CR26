#!/bin/bash

#========================================
# OpenFOAM Mesh Generation Script
#========================================

# Switch to script directory
cd "$(dirname "$0")" || exit 1
echo "Running in: $(pwd)"
echo "Script started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

#----------------------------------------
# Load OpenFOAM Environment
#----------------------------------------
echo "Loading OpenFOAM v2412 environment..."
start_time=$(date +%s)

if module avail openfoam/v2406 &>/dev/null; then
    module purge
    source ~/OpenFOAM/v2412/OpenFOAM-v2412/etc/bashrc
    numProcs=$SLURM_NTASKS
    echo "OpenFOAM v2412 loaded via module with $numProcs processors."
else
    source /opt/openfoam2406/etc/bashrc
    numProcs=4
    echo "OpenFOAM v2406 loaded from /opt with $numProcs processors."
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ OpenFOAM environment loaded (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Cleanup
#----------------------------------------
echo "Cleaning up previous results..."
start_time=$(date +%s)

rm -rf 0 processor* logs
cp -r 0.orig 0
foamCleanTutorials

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Cleanup completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Setup
#----------------------------------------
echo "Setting up directories and files..."
start_time=$(date +%s)

mkdir -p logs
touch foam.foam

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Setup completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Parse Geometry Parameter
#----------------------------------------
echo "Reading geometry parameter from parameters.cs..."
start_time=$(date +%s)

GEOMETRY=$(grep -E '^\s*Geometry\s+' parameters.cs | tail -n 1 | awk '{print $2}' | tr -d '";')

if [ -z "$GEOMETRY" ]; then
    echo "ERROR: Geometry parameter not found in parameters.cs"
    exit 1
fi

echo "Selected geometry: $GEOMETRY"

SOURCE_STL="constant/triSurface/${GEOMETRY}.stl"
TARGET_STL="constant/triSurface/rocket.stl"

if [ ! -f "$SOURCE_STL" ]; then
    echo "ERROR: Source file $SOURCE_STL not found!"
    exit 1
fi

cp "$SOURCE_STL" "$TARGET_STL"

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Geometry configuration completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# blockMesh
#----------------------------------------
echo "Running blockMesh..."
start_time=$(date +%s)

blockMesh > logs/blockMesh.log 2>&1

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ blockMesh completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Surface Feature Extraction
#----------------------------------------
echo "Extracting surface features..."
start_time=$(date +%s)

surfaceFeatureExtract > logs/surfaceFeatureExtract.log 2>&1
gzip -d constant/triSurface/rocket.eMesh.gz

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Surface feature extraction completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# STL Processing
#----------------------------------------
echo "Processing STL files..."
start_time=$(date +%s)

foamToSurface -tri -constant ./constant/triSurface/patches.stl

echo "Renaming solid entries in rocket.stl..."
sed -i 's/^solid .*/solid rocket/; s/^endsolid .*/endsolid rocket/' ./constant/triSurface/rocket.stl

echo "Combining rocket.stl and patches.stl..."
cat ./constant/triSurface/rocket.stl ./constant/triSurface/patches.stl > ./constant/triSurface/combined.stl

echo "Converting to FMS format..."
surfaceToFMS ./constant/triSurface/combined.stl

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ STL processing completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Cartesian Meshing
#----------------------------------------
echo "Running cartesianMesh..."
start_time=$(date +%s)

if ! cartesianMesh > logs/cartesianMesh.log 2>&1; then
    echo "ERROR: cartesianMesh failed - aborting"
    exit 1
fi

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ cartesianMesh completed (${elapsed}s = $((elapsed/60))m $((elapsed%60))s)"
echo "========================================"

#----------------------------------------
# Boundary Configuration
#----------------------------------------
echo "Configuring boundary conditions..."
start_time=$(date +%s)

gunzip ./constant/polyMesh/boundary.gz
foamDictionary ./constant/polyMesh/boundary -entry "entry0/inlet/type" -set "patch"
foamDictionary ./constant/polyMesh/boundary -entry "entry0/outlet/type" -set "patch"
foamDictionary ./constant/polyMesh/boundary -entry "entry0/sides/type" -set "patch"
foamDictionary ./constant/polyMesh/boundary -entry "entry0/rocket/type" -set "wall"

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Boundary configuration completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Mesh Quality Check
#----------------------------------------
echo "Running mesh quality checks..."
start_time=$(date +%s)

checkMesh > logs/checkMesh.log 2>&1
checkMesh -allGeometry -allTopology > logs/checkMeshAll.log 2>&1

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "✓ Mesh quality checks completed (${elapsed}s)"
echo "========================================"

#----------------------------------------
# Final Summary
#----------------------------------------
echo ""
echo "========================================"
echo "MESH GENERATION COMPLETED SUCCESSFULLY"
echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"