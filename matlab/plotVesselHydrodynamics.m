function vessel = plotVesselHydrodynamics(vessel_name)
% plotVesselHydrodynamics processes and plots MSS-Capytaine hydrodynamic data.
%
% The vessel structure is loaded automatically from:
%
%   vessels_capytaine/myVessel/results/myVessel.mat
%
% The function computes the MSS power-based maneuvering model at a wave peak
% frequency of 0.8 rad/s using the damping inputs exported from config.json.
% It displays the constant mass, damping, and restoring matrices and plots the
% force RAOs, added mass, radiation damping, and viscous damping. Natural
% periods and damping ratios are also reported for a surface vessel.
%
% Examples:
%   vessel = plotVesselHydrodynamics('testShip');
%
%   vessel = plotVesselHydrodynamics('LAUV_marie');
%
% MSS dependencies:
%   computeManeuveringModel.m
%   vesselPeriods.m
%   plotTF.m
%   plotABC.m
%   plotBv.m
%
% Author: Thor I. Fossen
% Date: 2026-10-07

vessel_name = validateVesselName(vessel_name);
project_root = fileparts(fileparts(mfilename('fullpath')));
vessel_file = fullfile(project_root, 'vessels_capytaine', vessel_name, ...
    'results', [vessel_name '.mat']);

if exist(vessel_file, 'file') ~= 2
    error('MSSCapytaine:VesselFileNotFound', ...
        ['Could not find the generated vessel file:\n%s\n' ...
         'Run "python main.py %s" from the MSS-Capytaine repository root.'], ...
        vessel_file, vessel_name);
end

vessel_data = load(vessel_file, 'vessel');
if ~isfield(vessel_data, 'vessel') || ~isstruct(vessel_data.vessel)
    error('MSSCapytaine:InvalidVesselFile', ...
        'The generated MATLAB file must contain an MSS vessel structure.');
end
vessel = vessel_data.vessel;

required_fields = {'main', 'MRB', 'A', 'B', 'C', 'freqs', ...
    'forceRAO', 'powerBased'};
for index = 1:numel(required_fields)
    if ~isfield(vessel, required_fields{index})
        error('MSSCapytaine:InvalidVessel', ...
            'The vessel structure is missing field "%s".', ...
            required_fields{index});
    end
end

if ~isfield(vessel.main, 'name') || ...
        ~strcmp(char(vessel.main.name), vessel_name)
    error('MSSCapytaine:InvalidVesselFile', ...
        'The loaded vessel.main.name must be "%s".', vessel_name);
end

omega_p = 0.8;
vessel = computeManeuveringModel(vessel, omega_p);

display(vessel.M, 'M')
display(vessel.D, 'D')
display(vessel.G, 'G')

is_submerged = isfield(vessel.main, 'submerged') && ...
    logical(vessel.main.submerged);
if ~is_submerged
    vesselPeriods(vessel.freqs, vessel.MRB, vessel.A, ...
        vessel.B + vessel.powerBased.Bv, vessel.G, 'coupled', true);
end

plotTF(vessel, 'force', 'rads')
plotABC(vessel, 'A')
plotABC(vessel, 'B')
plotBv(vessel)

end

function vessel_name = validateVesselName(vessel_name)
% Validate the catalogue name before using it to construct a file path.

if isstring(vessel_name) && isscalar(vessel_name)
    vessel_name = char(vessel_name);
end
if ~ischar(vessel_name)
    error('MSSCapytaine:InvalidVesselName', ...
        'Input must be a vessel catalogue name, such as ''myVessel''.');
end
vessel_name = strtrim(vessel_name);
if isempty(vessel_name) || ...
        isempty(regexp(vessel_name, '^[A-Za-z0-9_-]+$', 'once'))
    error('MSSCapytaine:InvalidVesselName', ...
        ['The vessel name must contain only letters, numbers, ' ...
         'underscores, and hyphens.']);
end

end
