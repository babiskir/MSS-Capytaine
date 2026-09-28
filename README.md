# MSS-Capytaine

MSS-Capytaine is a Python add-on for the [Marine Systems Simulator (MSS)](https://github.com/cybergalactic/MSS). It uses the open-source [Capytaine](https://capytaine.org/) boundary-element solver to compute 6-DOF linear potential-flow hydrodynamics and exports the results as the standard MATLAB/Octave `vessel` structure used by MSS.

The project provides an open-source hydrodynamic-data workflow for MSS users without access to the commercial ShipX or WAMIT solvers. Capytaine performs the boundary-element calculations; MSS provides the MATLAB and GNU Octave functions for analysis, model reduction, plotting, and time-domain simulation. 

The included example is a synthetic monohull defined by offset points. It demonstrates the complete Capytaine-to-MSS workflow rather than representing a validated vessel design. 

Author: Thor I. Fossen

Date: 2026-09-23

## MSS Toolbox Integration

The integration keeps the Python solver and MSS loosely coupled through a MATLAB data file:

```text
config.json (offset points)
            |
            v
   MSS-Capytaine mesh generation
            |
            v
     Capytaine BEM solution
            |
            v
Coordinate conversion and MSS export
            |
            v
 capytaineTestShip.mat (`vessel`)
            |
            v
 MSS HYDRO functions and MAIN LOOP vessel simulator
```

MSS-Capytaine converts the Capytaine results to the MSS conventions before export:

- Six degrees of freedom ordered as surge, sway, heave, roll, pitch, and yaw;
- Forward-starboard-down (FSD) body axes;
- Hydrodynamic matrices referenced to the center of gravity;
- Wave headings expressed as MSS propagation directions;
- Zero vessel speed for the current Capytaine calculation; and
- A full 0°–350° directional set obtained by mirroring the symmetric 0°–180° solution.

The exported `vessel` structure contains:

| Field | Contents |
| --- | --- |
| `main` | Vessel particulars, mass properties, centers, and metacentric heights |
| `MRB` | Rigid-body mass matrix |
| `A` | Zero-, finite-, and infinite-frequency added mass |
| `B` | Potential-flow radiation damping |
| `C` | Hydrostatic restoring matrix |
| `forceRAO` | First-order wave-excitation force RAOs |
| `motionRAO` | First-order motion RAOs computed with potential damping `B` |
| `freqs` | Coefficient frequency grid |
| `headings` | Full directional grid |
| `velocities` | Vessel-speed grid, currently `[0]` |
| `powerBased` | Inputs used by MATLAB to compute the constant power-based `Bv` |

A pre-generated copy of the example vessel is included in MSS under
[`HYDRO/vessels_capytaine/capytaineTestShip`](https://github.com/cybergalactic/MSS/tree/master/HYDRO/vessels_capytaine/capytaineTestShip).
Python and Capytaine are required to regenerate the hydrodynamic data, but not to load the included `.mat` file in MSS.

## Requirements

The Python calculation requires:

- Python 3.11 or later;
- Capytaine 3.0 or later;
- NumPy, SciPy, and Xarray; and
- Matplotlib for the optional Python plots.

The current workflow was developed and tested with Python 3.11 and Capytaine 3.0.0. A basic virtual environment can be created with:

```sh
python -m venv .venv
source .venv/bin/activate
python -m pip install capytaine numpy scipy xarray matplotlib
```

On Windows, activate the environment with `.venv\Scripts\activate` instead. MSS is not required to run the Python calculation, but it is required for the 
MATLAB/Octave post-processing workflow.

## Quick start

Run the hydrodynamic calculation from the repository root:

```sh
python main.py
```

`main.py` reads `capytaineTestShip/config.json` and writes the generated files to `capytaineTestShip/results/`.

To inspect the result using MSS, add MSS and its subfolders to the MATLAB or GNU Octave path, then run the supplied integration example:

```matlab
addpath(genpath('/path/to/MSS'))
run('matlab/dataCapytaine.m')
```

The MATLAB script:

1. Loads the generated `vessel` structure and hull panels;
2. Calls `computeManeuveringModel` to form an equivalent zero-speed model;
3. Calls `vesselPeriods` to calculate natural periods and damping ratios; and
4. Uses `plotTF`, `plotABC`, and `plotBv` to inspect the MSS hydrodynamic data.

## Repository layout

```text
main.py                         Run the example calculation
plot_results.py                 Plot the exported result using Python
src/                            Mesh, solver, coordinate, damping, and export code
capytaineTestShip/config.json   Example configuration
capytaineTestShip/offset_points.csv
                                Example hull offsets
capytaineTestShip/results/      Generated hydrodynamic data
matlab/dataCapytaine.m          MSS integration and plotting example
```

## Plot in Python

After running `main.py`, use Matplotlib to plot the saved MATLAB result:

```sh
python plot_results.py
python plot_results.py --heading 90 --show
```

The script reads `capytaineTestShip/results/capytaineTestShip.mat` and saves six PNG figures in `capytaineTestShip/results/plots/`. It does not rerun the hydrodynamics or change the result file. The coefficient plots show the infinite-frequency values as separate markers at the `10 rad/s` label; RAO plots use only finite frequencies.

## Inputs

`capytaineTestShip/offset_points.csv` contains the columns `x_m,z_m,half_breadth_m`. The origin is at midships on the design waterline; `x` points aft, `z` points upward, and half breadth is nonnegative. Each section runs from keel to waterline (`z = 0`).

`capytaineTestShip/config.json` specifies the mesh resolution, mass, radii of gyration (or an inertia-matrix CSV), center of mass, wave frequencies, and headings. Set `rotation_center_m` equal to `center_of_mass_m` for the CG-referenced export. The limiting-frequency calculations require infinite water depth, which is the default when `water_depth_m` is absent or `null`.

Set `submerged` to `false` for a surface vessel. The solver then generates an internal waterplane lid to suppress irregular-frequency artifacts. Set it to `true` for a submerged vehicle such as an AUV; no lid is generated.

`samples_per_section` controls resolution around each half section, while `number_of_stations` controls resolution along the hull. Check Capytaine's mesh-resolution warnings at the highest wave frequencies. The workflow symmetrizes the added-mass and radiation-damping matrices as required by zero-speed reciprocity. It reports a warning when the relative reciprocity error exceeds 1%, since that can indicate a mesh that needs checking or refinement.

## Viscous damping correction

The `viscous_damping` object contains the six dimensionless inputs used by MSS `computeManeuveringModel`. They are stored unchanged in `vessel.powerBased`; Python does not construct a second viscous-damping matrix. `kappa_126` gives relative damping increments for surge, sway, and yaw. `delta_zeta_345` gives additional damping ratios for heave, roll, and pitch:

```json
"viscous_damping": {
  "kappa_126": [0.05, 0.05, 0.05],
  "delta_zeta_345": [0, 0.1, 0]
}
```

The stored values document the selected damping assumptions and match the defaults in `computeManeuveringModel`. After loading the exported vessel, call `computeManeuveringModel(vessel, omega_p)`. It computes `A_eq`, `B_eq`, the single constant diagonal `powerBased.Bv`, and `D = B_eq + Bv`. For DOFs 1, 2, and 6, `Bvii = kappa_i B_eq,ii`. For DOFs 3, 4, and 5,
`Bvii = 2 delta_zeta_i sqrt(Mii Gii)`.

Capytaine motion RAOs use potential-flow damping only. No top-level frequency-dependent `vessel.Bv` is exported.

## Outputs

`capytaineTestShip/results/capytaineTestShip.mat` contains `MRB`, `A`, `B`, `C`, the power-based damping inputs, force and motion RAOs, frequencies, and headings in MSS forward-starboard-down axes at the center of gravity. The hydrostatic restoring matrix `C` has entries only in the heave, roll, and pitch block.

The coefficient frequency grid includes zero frequency and the infinite-frequency radiation solution, labeled `10 rad/s`. The force and motion RAOs use only the positive finite frequencies below `10 rad/s`. Headings solved from 0° to 180° are mirrored to a full 0° to 350° set.

The results directory also contains `hydrostatics.json` and the generated hull panels in `.mat` and `.npz` formats. The hull and inertia values are synthetic demonstration data; numerical accuracy depends on mesh resolution.

## Current scope and limitations

- The calculation is restricted to zero forward speed.
- The exported RAOs are first-order; second-order wave-drift loads are not computed.
- Directional mirroring assumes a port-starboard symmetric monohull.
- Zero- and infinite-frequency radiation calculations currently require infinite water depth.
- Mesh convergence and frequency-range convergence must be checked for each new hull.

## Related projects

- [MSS](https://github.com/cybergalactic/MSS) — MATLAB and GNU Octave marine systems simulation library.
- [Capytaine](https://github.com/capytaine/capytaine) — Python boundary-element solver for linear potential-flow hydrodynamics.
