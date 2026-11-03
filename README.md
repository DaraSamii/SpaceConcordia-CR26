# CR26 — Two-Stage Supersonic Rocket CFD & Flight Analysis

CFD study and post-flight telemetry analysis of Space Concordia's **CR26** two-stage rocket, using OpenFOAM and cfMesh. The repository contains the simulation case, the HPC job generator, the post-processing notebooks and the results.

![Team at Launch Canada 2026](readme_imgs/team.jpg)

<p align="center">
  <img src="readme_imgs/launch.jpg" alt="CR26 lift-off" width="360">
</p>

# Abstract
CR26 is Space Concordia's two-stage (booster + sustainer) rocket, launched at Launch Canada on August 19, 2026. Following the [CR25 (Aether) study](https://github.com/DaraSamii/SpaceConcordi-CR25), CFD was used to give the design team the aerodynamic coefficients, centre of pressure and distributed loads of the vehicle in both configurations:

- **TwoStage**: booster + sustainer stacked (boost phase)
- **OneStage**: sustainer alone (after separation)

After the flight, the GPS/LoRa telemetry of both stages was analysed.

For the theory behind the setup (governing equations, turbulence model, mesh strategy, HPC workflow) see the [CR25 report](https://github.com/DaraSamii/SpaceConcordi-CR25/blob/main/CFD_spaceConcordia.pdf); the same methodology is used here.

# Flight Result

| | Booster | Sustainer |
|---|---|---|
| Apogee (AGL) | 14,364 ft (4,378 m) at T+24.8 s | **47,991 ft (14,628 m)** at T+51.6 s |
| Max observed speed | 1,002 ft/s (305 m/s)\* | 1,599 ft/s (487 m/s) |
| Peak Mach observed | 0.92\* | **1.54** |

\* follows a telemetry gap; the true booster peak is higher. See [telemetry/telemetry_analysis.ipynb](telemetry/telemetry_analysis.ipynb).

![Altitude profile](readme_imgs/fig02_altitude_profile.png)
![3D trajectory](readme_imgs/fig06_trajectory_3d.png)

# Repository Structure
```
CR26/
├── original/                 # OpenFOAM template case (copied for each run)
│   ├── 0.orig/               # initial / boundary conditions (U, p, T, k, omega, nut, alphat)
│   ├── constant/
│   │   ├── thermophysicalProperties
│   │   ├── turbulenceProperties
│   │   └── triSurface/       # OneStage.stl, TwoStage.stl geometries
│   ├── system/               # meshDict (cfMesh), fvSchemes(.stable/.accurate), fvSolution, controlDict ...
│   ├── parameters.cs         # Geometry, Ma, AoA, maxCellSize, domain size
│   ├── Mesh.sh               # blockMesh → surfaceFeatureExtract → cartesianMesh → checkMesh
│   ├── Allrun.sh             # decompose → rhoSimpleFoam → reconstruct → VTK export
│   ├── submit.sh             # SLURM job script
│   ├── Resume.sh             # restart rhoSimpleFoam from the latest decomposed time
│   ├── submitResume.sh       # SLURM job script for Resume.sh
│   └── Pserver.sh            # ParaView server on the cluster
├── SubmitAll.py              # generates + submits mesh study and Geometry × Ma × AoA sweep
├── cfMeshInstall.sh          # builds cfMesh
├── cleanAnalysis.ipynb       # CFD post-processing (mesh study, coefficients, CoP, validation, forces)
├── results/                  # CFD plots (PDF) produced by cleanAnalysis.ipynb
├── validation/               # RASAero / OpenRocket reference data
├── openrocket/               # OpenRocket design file (V5.1) and its report
├── telemetry/                # raw ground-station logs, flight analysis notebook, figures
└── readme_imgs/
```

# Workflow
1. Build cfMesh: `bash cfMeshInstall.sh`
2. Set the case in `original/parameters.cs` (`Geometry`, `Ma`, `AoA`, `maxCellSize`) and run `./Mesh.sh && ./Allrun.sh`, or
3. On the cluster, run `python SubmitAll.py` to create and submit every case of the mesh study and the parametric sweep.
4. Gather the cases into `OpenFOAM_Results_gathered/` and run `cleanAnalysis.ipynb`.

The raw simulation output (~11 GB) is not in the repository.

# Simulation Setup

| | |
|---|---|
| Solver | `rhoSimpleFoam` (steady, compressible RANS) |
| Turbulence | k-ω SST |
| Mesher | cfMesh `cartesianMesh` with boundary-layer inflation |
| Geometries | OneStage (sustainer), TwoStage (booster + sustainer) |
| Mach | 1.2 – 2.4 (step 0.2) |
| Angle of attack | 1° – 5° (step 1°) |
| Mesh study | `maxCellSize` 2.4, 2.2, 2.0, 1.8, 1.6 |
| Freestream | p = 101325 Pa, T = 300 K |

**Air properties**

| Property | Value | Units |
|----------|-------|-------|
| Molar mass (M) | 28.9 | g/mol |
| Specific heat (C_p) | 1005 | J/(kg·K) |
| Sutherland constant (A_s) | 1.4792×10⁻⁶ | kg/(m·s·K^0.5) |
| Sutherland temperature (T_s) | 116 | K |
| Prandtl number (Pr) | 0.7 | - |

# Mesh

**Refinement levels:**
![Mesh diagram](readme_imgs/CR26_diag.png)

**Overview:**
![Mesh overview](readme_imgs/view.jpg)

**Nose tip:**
![Nose tip mesh](readme_imgs/nosetip.jpg)

**Fins:**
![Fin mesh](readme_imgs/first_fin.jpg)
![Fin mesh zoom](readme_imgs/finzoom.jpg)

## Mesh independence
<p>
  <img src="readme_imgs/CdMesh.png" width="49%">
  <img src="readme_imgs/errorMesh.png" width="49%">
</p>

# Results

## Verification
![Solver residuals](readme_imgs/Onesolver_residuals.png)
![Cd convergence](readme_imgs/Cd_and_deltaCd_vs_Time.png)

## Validation against RASAero
| OneStage | TwoStage |
|---|---|
| ![](readme_imgs/One_Cd_comparison.png) | ![](readme_imgs/Two_Cd_comparison.png) |
| ![](readme_imgs/One_Cp_comparison.png) | ![](readme_imgs/Two_Cp_comparison.png) |

## Centre of pressure
| OneStage | TwoStage |
|---|---|
| ![](readme_imgs/One_CopX_vs_Ma.png) | ![](readme_imgs/Two_CopX_vs_Ma.png) |

## Contours (Ma 2.0, AoA 3°)

### Mach
![TwoStage Mach](readme_imgs/TwoStage_Ma2.0_AoA3.0_Ma.png)
![OneStage Mach](readme_imgs/OneStage_Ma2.0_AoA3.0_Ma.png)

### Pressure
![TwoStage p](readme_imgs/TwoStage_Ma2.0_AoA3.0_p.png)
![OneStage p](readme_imgs/OneStage_Ma2.0_AoA3.0_p.png)

### Temperature
![TwoStage T](readme_imgs/TwoStage_Ma2.0_AoA3.0_T.png)
![OneStage T](readme_imgs/OneStage_Ma2.0_AoA3.0_T.png)

## Nose-tip temperature
![Nose tip temperature](readme_imgs/Nosetip_Temperature_TwoStage.png)

## Force loads
![Forces at Ma 2](readme_imgs/forces_Ma2.jpg)
![Normal force vs Mach](readme_imgs/Fy_vs_Ma.png)

