function plotVesselMesh(vessel_name)
% plotVesselMesh plots the generated hull-panel mesh for an MSS-Capytaine
% catalogue vessel.
%
% The vessel structure and corresponding mesh are loaded automatically from:
%
%   vessels_capytaine/myVessel/results/myVessel.mat
%   vessels_capytaine/myVessel/results/generated_hull_panels.mat
%
% Examples:
%   plotVesselMesh('testShip')
%
%   plotVesselMesh('LAUV_marie')
%
% The vessel catalogue folder, vessel.main.name, and output filename must use
% the same vessel name.
%
% Author: Thor I. Fossen
% Date: 2026-10-07

vessel_name = validateVesselName(vessel_name);

project_root = fileparts(fileparts(mfilename('fullpath')));
results_dir = fullfile(project_root, 'vessels_capytaine', vessel_name, ...
    'results');
vessel_file = fullfile(results_dir, [vessel_name '.mat']);
mesh_file = fullfile(results_dir, 'generated_hull_panels.mat');

if exist(vessel_file, 'file') ~= 2
    error('MSSCapytaine:VesselFileNotFound', ...
        ['Could not find the generated vessel file:\n%s\n' ...
         'Run "python main.py %s" from the MSS-Capytaine repository root.'], ...
        vessel_file, vessel_name);
end

vessel_data = load(vessel_file, 'vessel');
if ~isfield(vessel_data, 'vessel') || ~isstruct(vessel_data.vessel) || ...
        ~isfield(vessel_data.vessel, 'main') || ...
        ~isfield(vessel_data.vessel.main, 'name') || ...
        ~strcmp(char(vessel_data.vessel.main.name), vessel_name)
    error('MSSCapytaine:InvalidVesselFile', ...
        ['The file must contain an MSS vessel structure whose ' ...
         'vessel.main.name is "%s".'], vessel_name);
end

if exist(mesh_file, 'file') ~= 2
    error('MSSCapytaine:MeshFileNotFound', ...
        ['Could not find the generated mesh for vessel "%s":\n%s\n' ...
         'Run "python main.py %s" from the MSS-Capytaine repository root.'], ...
        vessel_name, mesh_file, vessel_name);
end

mesh_data = load(mesh_file, 'vertices', 'faces');
if ~isfield(mesh_data, 'vertices') || ~isfield(mesh_data, 'faces')
    error('MSSCapytaine:InvalidMeshFile', ...
        'The generated mesh file must contain vertices and faces.');
end

vertices = mesh_data.vertices;
faces = mesh_data.faces;
if ~isnumeric(vertices) || size(vertices, 2) ~= 3 || ...
        any(~isfinite(vertices(:)))
    error('MSSCapytaine:InvalidVertices', ...
        'Hull-panel vertices must be a finite numeric N-by-3 array.');
end
if ~isnumeric(faces) || size(faces, 2) < 3
    error('MSSCapytaine:InvalidFaces', ...
        'Hull-panel faces must be a numeric array with at least three columns.');
end

% Capytaine represents every triangle as a four-index face with the final
% vertex repeated. Retain the three unique triangle vertices so MATLAB does
% not render the degenerate fourth patch edge as a long ray.
triangles = double(faces(:, 1:3));
number_of_vertices = size(vertices, 1);
if any(~isfinite(triangles(:))) || ...
        any(triangles(:) ~= fix(triangles(:))) || ...
        any(triangles(:) < 1) || ...
        any(triangles(:) > number_of_vertices)
    error('MSSCapytaine:InvalidFaces', ...
        'Hull-panel faces contain invalid MATLAB vertex indices.');
end

figure_name = [vessel_name ' hull-panel mesh'];
figure_tag = ['MSSCapytaineMesh:' vessel_name];
mesh_figure = findobj(0, 'Type', 'figure', 'Tag', figure_tag);
if isempty(mesh_figure)
    mesh_figure = figure('Name', figure_name, ...
        'NumberTitle', 'off', 'Tag', figure_tag);
else
    mesh_figure = mesh_figure(1);
    clf(mesh_figure)
    figure(mesh_figure)
end
mesh_axes = axes('Parent', mesh_figure);

trisurf(triangles, vertices(:, 1), vertices(:, 2), vertices(:, 3), ...
    'Parent', mesh_axes, ...
    'FaceColor', [0.8 0.8 0.8], ...
    'EdgeColor', 'none');

mesh_edges = [triangles(:, [1 2]); ...
              triangles(:, [2 3]); ...
              triangles(:, [3 1])];
mesh_edges = unique(sort(mesh_edges, 2), 'rows');
number_of_edges = size(mesh_edges, 1);

edge_x = [vertices(mesh_edges(:, 1), 1), ...
          vertices(mesh_edges(:, 2), 1), nan(number_of_edges, 1)]';
edge_y = [vertices(mesh_edges(:, 1), 2), ...
          vertices(mesh_edges(:, 2), 2), nan(number_of_edges, 1)]';
edge_z = [vertices(mesh_edges(:, 1), 3), ...
          vertices(mesh_edges(:, 2), 3), nan(number_of_edges, 1)]';

hold(mesh_axes, 'on')
plot3(mesh_axes, edge_x(:), edge_y(:), edge_z(:), 'k-', ...
    'LineWidth', 0.5)
hold(mesh_axes, 'off')

axis(mesh_axes, 'equal')
grid(mesh_axes, 'on')
xlabel(mesh_axes, 'x [m]')
ylabel(mesh_axes, 'y [m]')
zlabel(mesh_axes, 'z [m]')
title(mesh_axes, figure_name, 'Interpreter', 'none')
view(mesh_axes, 3)

end

function vessel_name = validateVesselName(vessel_name)
% Validate the catalogue name before using it to construct file paths.

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
