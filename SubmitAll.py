import os
import shutil
import re
import subprocess

#===================================================================================================
def copy_and_modify_case(original_dir, data_dir, copied_folder, modifications, job_name):
    """
    Copies the OpenFOAM case directory, modifies parameters, updates submit.sh, and submits the job.
    
    :param original_dir: Path to the original directory
    :param data_dir: Path to the data directory where the copied folder will reside
    :param copied_folder: Name of the copied folder
    :param modifications: Dictionary of variable names and their new values
    :param job_name: The job name to set in the submit.sh script
    """
    # Define paths
    destination_path = os.path.join(data_dir, copied_folder)
    parameters_file = os.path.join(destination_path, "parameters.cs")
    submit_script = os.path.join(destination_path, "submit.sh")
    initial_dir = os.getcwd()

    # Step 1: Copy the directory
    if os.path.exists(destination_path):
        shutil.rmtree(destination_path)
    shutil.copytree(original_dir, destination_path)
    print(f"Copied '{original_dir}' to '{destination_path}'.")

    # Step 2: Modify parameters file
    if not os.path.exists(parameters_file):
        raise FileNotFoundError(f"Parameters file not found: {parameters_file}")

    with open(parameters_file, 'r') as file:
        lines = file.readlines()

    for variable, new_value in modifications.items():
        # Handle both numeric values and string values (like Geometry)
        if variable == "Geometry":
            # Special handling for Geometry parameter with quotes
            param_pattern = re.compile(rf'^\s*{variable}\s+"[^"]*";')
            for i, line in enumerate(lines):
                if param_pattern.match(line):
                    lines[i] = f'{variable} "{new_value}";\n'
                    print(f"Updated '{variable}' to \"{new_value}\" in {parameters_file}.")
                    break
            else:
                raise ValueError(f"Variable '{variable}' not found in parameters file.")
        else:
            # Handle numeric parameters
            param_pattern = re.compile(rf'^\s*{variable}\s+([\d.eE+-]+);')
            for i, line in enumerate(lines):
                if param_pattern.match(line):
                    lines[i] = f"{variable} {new_value};\n"
                    print(f"Updated '{variable}' to {new_value} in {parameters_file}.")
                    break
            else:
                raise ValueError(f"Variable '{variable}' not found in parameters file.")

    with open(parameters_file, 'w') as file:
        file.writelines(lines)

    # Step 3: Modify submit.sh
    if not os.path.exists(submit_script):
        raise FileNotFoundError(f"Submit script not found: {submit_script}")

    with open(submit_script, 'r') as file:
        submit_lines = file.readlines()

    for i, line in enumerate(submit_lines):
        if line.startswith("#SBATCH --job-name="):
            submit_lines[i] = f"#SBATCH --job-name={job_name}\n"
            print(f"Updated job name in submit.sh to '{job_name}'.")
            break

    with open(submit_script, 'w') as file:
        file.writelines(submit_lines)

    # Step 4: Submit the job
    try:
        os.chdir(destination_path)
        print(f"Submitting job from directory: {os.getcwd()}")

        # Run sbatch
        result = subprocess.run(["sbatch", "submit.sh"], capture_output=True, text=True)
        print(f"Command executed: sbatch submit.sh")
        print(f"Return code: {result.returncode}")
        print(f"Stdout: {result.stdout}")
        print(f"Stderr: {result.stderr}")

        if result.returncode == 0:
            print(f"Job submitted successfully. Output:\n{result.stdout}")
        else:
            print(f"Failed to submit job. Error:\n{result.stderr}")
    except Exception as e:
        print(f"Error while submitting job: {e}")
    finally:
        os.chdir(initial_dir)

#===================================================================================================

# STUDY 1: MESH SIZE STUDY
#===================================================================================================
print("\n" + "="*70)
print("STARTING MESH SIZE STUDY")
print("="*70)

original_dir = "./original"
data_dir_mesh = "./Data/Mesh_Study"

# Define mesh size variations
mesh_sizes = [2.0, 1.8, 1.6, 1.4, 1.2, 1.0, 0.8]

# Create summary list
mesh_summary = []

# Loop over mesh sizes
for mesh_size in mesh_sizes:
    # Create folder name based on mesh size
    mesh_str = f"{mesh_size:.1f}".replace('.', 'p')
    copied_folder = f"mesh_{mesh_str}"
    job_name = f"mesh{mesh_str}"
    
    # Only modify the maxCellSize parameter
    modifications = {"maxCellSize": mesh_size}
    
    print(f"\n{'='*60}")
    print(f"Creating case: Mesh Size = {mesh_size}")
    print(f"Folder name: {copied_folder}")
    print(f"Job name: {job_name}")
    print(f"{'='*60}")
    
    copy_and_modify_case(original_dir, data_dir_mesh, copied_folder, modifications, job_name)
    mesh_summary.append((mesh_size, copied_folder))

print(f"\n{'='*70}")
print("MESH SIZE STUDY COMPLETED!")
print(f"{'='*70}")
print("\nSummary of Mesh Study cases:")
for mesh_size, folder_name in mesh_summary:
    print(f"  - {folder_name}: maxCellSize = {mesh_size}")

#===================================================================================================
# STUDY 2: GEOMETRY, MACH, AND AOA STUDY
#===================================================================================================
print("\n" + "="*70)
print("STARTING GEOMETRY, MACH NUMBER, AND ANGLE OF ATTACK STUDY")
print("="*70)

data_dir_parametric = "./Data/Parametric_Study"

# Define parametric study ranges
geometries = ["OneStage", "TwoStage"]
Ma_values = [1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4]
AoA_values = [1.0, 2.0, 3.0, 4.0, 5.0]

# Create summary list
parametric_summary = []
case_counter = 0

# Loop over geometries, Mach numbers, and AoA
for geometry in geometries:
    print(f"\n{'*'*70}")
    print(f"Creating cases for {geometry} geometry")
    print(f"{'*'*70}")
    
    for Ma in Ma_values:
        for AoA in AoA_values:
            case_counter += 1
            
            # Create folder structure: Parametric_Study/OneStage/Ma_1p2_AoA_1p0
            Ma_str = f"{Ma:.1f}".replace('.', 'p')
            AoA_str = f"{AoA:.1f}".replace('.', 'p')
            copied_folder = os.path.join(geometry, f"Ma_{Ma_str}_AoA_{AoA_str}")
            job_name = f"{geometry[:3]}M{Ma_str}A{AoA_str}"
            
            # Define modifications for all parameters
            modifications = {
                "Geometry": geometry,
                "Ma": Ma,
                "AoA": AoA
            }
            
            print(f"\n{'='*60}")
            print(f"Case {case_counter}: Geometry = {geometry}, Ma = {Ma:.1f}, AoA = {AoA:.1f}°")
            print(f"Folder path: {os.path.join(data_dir_parametric, copied_folder)}")
            print(f"Job name: {job_name}")
            print(f"{'='*60}")
            
            copy_and_modify_case(original_dir, data_dir_parametric, copied_folder, modifications, job_name)
            parametric_summary.append((geometry, Ma, AoA, copied_folder))

print(f"\n{'='*70}")
print("PARAMETRIC STUDY COMPLETED!")
print(f"{'='*70}")

# Print summary by geometry
for geometry in geometries:
    print(f"\n{geometry} Cases ({sum(1 for g, _, _, _ in parametric_summary if g == geometry)} total):")
    count = 0
    for geom, ma, aoa, folder in parametric_summary:
        if geom == geometry:
            count += 1
            print(f"  {count}. {folder}: Ma = {ma:.1f}, AoA = {aoa:.1f}°")

#===================================================================================================
# FINAL SUMMARY
#===================================================================================================
print("\n" + "="*70)
print("ALL STUDIES COMPLETED - FINAL SUMMARY")
print("="*70)
print(f"\nTotal cases created:")
print(f"  - Mesh Study: {len(mesh_summary)} cases")
print(f"  - Parametric Study: {len(parametric_summary)} cases")
print(f"    * OneStage: {sum(1 for g, _, _, _ in parametric_summary if g == 'OneStage')} cases")
print(f"    * TwoStage: {sum(1 for g, _, _, _ in parametric_summary if g == 'TwoStage')} cases")
print(f"  - TOTAL: {len(mesh_summary) + len(parametric_summary)} cases")