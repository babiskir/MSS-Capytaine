# Capytaine vessel catalogue

Each subdirectory is a self-contained vessel case with a `config.json`, hull
offsets, documentation where needed, and a generated `results/` directory.

| Case | Type | Description |
| --- | --- | --- |
| [`testShip`](testShip/) | Surface vessel | Synthetic monohull used to test the complete workflow |
| [`LAUV_marie`](LAUV_marie/) | Submerged vehicle | Idealized model of NTNU's OceanScan LAUV Marie |

From the repository root, list or run cases with:

```sh
python main.py --list
python main.py testShip
python main.py LAUV_marie
```

The default case is `testShip`.

Each case stores the damping inputs expected by MSS
`computeManeuveringModel` under `viscous_damping` in its configuration.
Surface vessels use `kappa_126` and `delta_zeta_345`. Submerged vehicles use
the four target time constants `T_1236` and the roll/pitch damping-ratio
increments `delta_zeta_45`. The exporter writes the applicable pair to
`vessel.powerBased`.

Inspect the generated cases with MSS from MATLAB or GNU Octave:

```matlab
addpath(genpath('/path/to/MSS'))
addpath('/path/to/MSS-Capytaine/matlab')
plotTestShip
plotLAUV_marie
```

The two plotting functions load their case data, compute the MSS maneuvering
model, draw the hull-panel mesh in separate case-specific figures, and plot
the hydrodynamic coefficients and force RAOs.

To refresh the pre-generated MSS catalogue after a solve, copy the resulting
`.mat` file to the matching directory under
`MSS/HYDRO/vessels_capytaine/<case>/`.
