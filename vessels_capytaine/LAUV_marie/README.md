# LAUV_marie

LAUV means Light Autonomous Underwater Vehicle. The LAUV platform family was
developed by the University of Porto's LSTS and is commercialized by OceanScan.
Marie is NTNU AUR-Lab's particular OceanScan LAUV. This `LAUV_marie` case is
an idealized submerged hydrodynamic model inspired by
[NTNU's LAUV Marie](https://www.ntnu.edu/aur-lab/lauv-marie) and the
[OceanScan LAUV family](https://lsts.fe.up.pt/systems/53).

NTNU publishes a length of 2.15 m and a mass in air of 34 kg for Marie. The
0.15 m diameter is the published diameter of the OceanScan LAUV family.

The exact LAUV Marie hull offsets, mass distribution, centers of gravity and
buoyancy, and appendage geometry are not public. This case therefore uses a
generic axisymmetric body: a 1.45 m cylindrical midbody with equal 0.35 m
ellipsoidal tapers. Fins, antennas, sonar heads, and the propeller are omitted.
The transverse radius of gyration is based on a uniform cylinder, and the
center of gravity is assumed to be 0.01 m below the center of buoyancy.

The body-fixed offset geometry is centered on the origin. For the Capytaine
free-surface calculation it is placed at a nominal center depth of 1.0 m.
This translation is not included in the MSS body-fixed CG, CB, or panel
coordinates.

The finite-frequency grid runs from 0.1 to 9.5 rad/s. It is densest across the
approximately 1--5 rad/s free-surface interaction range for a body at 1 m
depth, and becomes coarser as the coefficients converge toward the separately
calculated infinite-frequency solution. Zero-frequency radiation coefficients
are calculated separately, so near-zero finite points are unnecessary. The
infinity result is stored at the conventional 10 rad/s plotting position and
is not a finite-frequency calculation.

Run this case from the repository root:

    python main.py LAUV_marie

The generated MSS structure is written to
vessels_capytaine/LAUV_marie/results/LAUV_marie.mat.

Plot the generated coefficients and RAOs from the repository root with:

    python plot_results.py vessels_capytaine/LAUV_marie/results/LAUV_marie.mat

Select another wave heading, for example 90 degrees, with:

    python plot_results.py vessels_capytaine/LAUV_marie/results/LAUV_marie.mat --heading 90

The figures are saved in
vessels_capytaine/LAUV_marie/results/plots/.

With MSS on the MATLAB or GNU Octave path, inspect the generated vessel and
hull-panel mesh using the repository's MATLAB plotting function:

    addpath('/path/to/MSS-Capytaine/matlab')
    plotLAUV_marie

The function returns the processed MSS vessel structure when called with an
output argument:

    vessel = plotLAUV_marie();
