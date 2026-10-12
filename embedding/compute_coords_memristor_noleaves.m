function compute_coords_memristor_noleaves
filename = "npc_topology_adjacency-noin";
fprintf('=== Starting %s ===\n', mfilename);
fprintf('Loading file: %s.mat\n', filename);
load(filename + ".mat", 'A_noin', 'node_ranges_noin');

A = A_noin;
node_ranges = node_ranges_noin;

adj = A; 
N = size(adj, 1);
fprintf('Loaded full network with %d nodes.\n', N);

%% Compute average degree per node type (optional, keep as is)
degree_full = sum(adj > 0, 2);  % degree for each node (sparse)

fprintf('\n--- Average degree per node type ---\n');
node_types = {'S1', 'D1', 'SO1', 'S2', 'D2', 'SO2'};
for t = 1:length(node_types)
    type_name = node_types{t};
    if isfield(node_ranges, type_name)
        range = node_ranges.(type_name);
        idx = range(1):range(2);
        avg_deg = mean(full(degree_full(idx)));
        fprintf('  %s: average degree = %.2f (N = %d)\n', type_name, avg_deg, length(idx));
    else
        fprintf('  %s: field not found in node_ranges\n', type_name);
    end
end

% --- Manually construct attributes based on node_ranges ---
fprintf('\n--- Generating node attributes ---\n');

color_matrix = zeros(N, 3);
communitylayer = zeros(N, 1);
communitysymbol = zeros(N, 1);

red        = [0.752941176470588, 0, 0];
lightGreen = [0.247058823529412, 0.682352941176471, 0.00784313725490196];
darkGreen  = [0.329411764705882, 0.509803921568627, 0.207843137254902];

if isfield(node_ranges, 'S1')
    range = node_ranges.S1;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(red, length(idx), 1);
    communitysymbol(idx) = 1; communitylayer(idx) = 1;
end
if isfield(node_ranges, 'D1')
    range = node_ranges.D1;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(lightGreen, length(idx), 1);
    communitysymbol(idx) = 2; communitylayer(idx) = 1;
end
if isfield(node_ranges, 'SO1')
    range = node_ranges.SO1;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(darkGreen, length(idx), 1);
    communitysymbol(idx) = 3; communitylayer(idx) = 1;
end
if isfield(node_ranges, 'S2')
    range = node_ranges.S2;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(red, length(idx), 1);
    communitysymbol(idx) = 1; communitylayer(idx) = 2;
end
if isfield(node_ranges, 'D2')
    range = node_ranges.D2;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(lightGreen, length(idx), 1);
    communitysymbol(idx) = 2; communitylayer(idx) = 2;
end
if isfield(node_ranges, 'SO2')
    range = node_ranges.SO2;
    idx = range(1):range(2);
    color_matrix(idx, :) = repmat(darkGreen, length(idx), 1);
    communitysymbol(idx) = 3; communitylayer(idx) = 2;
end

%% 3. Embedding parameters
pw = {'EBC'};
ndr = {'ncISO'};
rt = {'pre_we_type1'};
aa = {'EA'};

fprintf('\nParameters:\n');
fprintf('  preweighting: %s\n', pw{1});
fprintf('  dim reduction: %s\n', strjoin(ndr, ', '));
fprintf('  radial types: %s\n', strjoin(rt, ', '));
fprintf('  angular adjust: %s\n', aa{1});

%% 4. Embed the leaf-stripped core and restore the leaves
embedding_modes = {'leaf'};
for p = 1:length(pw)
    pw_i = pw{p};
for mode_idx = 1:length(embedding_modes)
    embed_mode = embedding_modes{mode_idx};
    fprintf('\n========================================================\n');
    fprintf('  EMBEDDING MODE: %s\n', upper(embed_mode));
    fprintf('========================================================\n');
    
    % ---- Prepare adjacency and leaf indices for this mode ----
    if strcmp(embed_mode, 'full')
        % Use full network (no leaf removal)
        adj_work = adj;
        leaf_idx = [];
        nonleaf_idx = 1:N;
        core_adj = adj_work;
        core_idx = 1:N;
        % No need to store core coordinates separately – we embed the whole graph.
    else   % 'leaf' mode
        % Remove leaf nodes (degree == 1) to work on the core only
        degree_full = sum(adj > 0, 2);
        leaf_idx = find(degree_full == 1);
        nonleaf_idx = find(degree_full > 1);
        fprintf('  Leaf nodes (deg=1): %d\n', length(leaf_idx));
        fprintf('  Non‑leaf (core) nodes: %d\n', length(nonleaf_idx));
        
        % Core adjacency and attributes (used only for embedding)
        adj_work = adj(nonleaf_idx, nonleaf_idx);
        core_adj = adj_work;
        core_idx = nonleaf_idx;
    end
    
    % ---- Loop over dimension reduction methods (ndr) ----
    aa_k = aa{1};   % angular adjustment fixed
    rt_l = rt{1};   % radial type used by coalescent_embedding
    
    for j = 1:length(ndr)
 
        fprintf('\n--- Processing: mode=%s, pw=%s, ndr=%s, aa=%s ---\n', ...
                embed_mode, pw_i, ndr{j}, aa_k);
        
        % ---- Define base name (including embedding mode) ----
        base_no_rad = sprintf('%s_%s_%s_%s_%s', filename, embed_mode, pw_i, ndr{j}, aa_k);
        
        % ---- Compute embedding (full or core) ----
        out_mat = [base_no_rad, '.mat'];
        if ~exist(out_mat, 'file')
            fprintf('  Computing embedding with coalescent_embedding...\n');
            coords_work = coalescent_embedding(...
                adj_work, pw_i, ndr{j}, rt_l, aa_k, 2);
            save(out_mat, 'coords_work');
            fprintf('  Embedding saved to: %s\n', out_mat);
        else
            fprintf('  Embedding file already exists. Loading...\n');
            data = load(out_mat, 'coords_work');
            coords_work = data.coords_work;
        end
        
        % ---- Prepare full coordinates (after adding leaves if needed) ----
        % coords_work is either full coordinates (full mode) or core coordinates (leaf mode)
        
        if strcmp(embed_mode, 'full')
            coords_full_temp = coords_work;
        else   % leaf mode: add leaves back
            fprintf('  Adding leaves back to obtain full coordinates...\n');
            % We will later recompute radials for core using exact/power,
            % but here we keep the angular part from coords_work.
            % The radial coordinates of the core will be overwritten in the inner loop.
            % So we just keep coords_work (which has both angular and radial from embedding).
            % We will later replace radial coordinates.
            coords_full_temp = NaN(N, 2);
            coords_full_temp(nonleaf_idx, :) = coords_work;
        end
        
        % ---- Recompute radial coordinates using different methods (exact, power) ----
        radial_methods = {'exact', 'power'};
        % Pre‑weight the full adjacency once (used for both radial methods when computing radials on full graph)
        xw_full = compute_preweighted(adj, pw_i);
        core_xw = compute_preweighted(core_adj, pw_i);
        for r = 1:length(radial_methods)
            rad_method = radial_methods{r};
            fprintf('    Recomputing radial coordinates with method: %s\n', rad_method);
            
            if strcmp(embed_mode, 'full')
                % Full mode: compute radial coordinates on the full graph
                if strcmp(rad_method, 'exact')
                    radial_new_full = set_radial_coordinates_1_exact(xw_full);
                else
                    radial_new_full = set_radial_coordinates_1_power(xw_full);
                end
                coords_new = coords_full_temp;
                coords_new(:,2) = radial_new_full(:);
            else
                core_n = size(core_xw, 1);

                % Compute gamma and beta from the full network, including leaves.
                strength_full = full(sum(xw_full,1))';
                if all(strength_full == strength_full(1))
                    error('All nodes have same strength');
                end
                gamma_range = 1.01:0.01:10.00;
                if length(strength_full) < 100
                    gamma = plfit(strength_full, 'finite', 'range', gamma_range);
                else
                    gamma = plfit(strength_full, 'range', gamma_range);
                end
                beta = 1 / (gamma - 1);
                
                % Compute radial_by_rank_total for all N nodes
                radial_by_rank_total = max(0, 2*beta*log(1:N) + 2*(1-beta)*log(N));
                
                % Assign equal strengths the same radius.
                strength_core = full(sum(core_xw,1))';
                [strength_sorted, sort_idx] = sort(strength_core, 'descend');

                radial_core = zeros(core_n, 1);
                i = 1;
                while i <= core_n
                    j = i;
                    while j < core_n && strength_sorted(j+1) == strength_sorted(i)
                        j = j + 1;
                    end
                    median_rank = round((i + j)/2);
                    group_radius = radial_by_rank_total(median_rank);
                    for k = i:j
                        radial_core(sort_idx(k)) = group_radius;
                    end
                    i = j + 1;
                end
                radial_core = radial_core(:);
                
                leaf_radial = max(radial_core) + 1;
                
                % Build full radial array
                radial_all = zeros(N, 1);
                radial_all(nonleaf_idx) = radial_core;
                if ~isempty(leaf_idx)
                    radial_all(leaf_idx) = leaf_radial;
                end
                
                % Combine angular (from core embedding) with new radials
                coords_new = NaN(N, 2);
                coords_new(nonleaf_idx, 1) = coords_work(:, 1);   % keep core angular
                coords_new(:, 2) = radial_all;
                
                % Assign leaf angles
                if ~isempty(leaf_idx)
                    coords_new = add_leaves_simple(adj, coords_new(nonleaf_idx,:), nonleaf_idx, radial_all);
                end
            end
            
            % ---- Save files with radial method in filename ----
            base_rad = sprintf('%s_radial_%s', base_no_rad, rad_method);
            csv_filename = [base_rad, '_coords.csv'];
            writematrix(coords_new, csv_filename);
            fprintf('    Coordinates saved to: %s\n', csv_filename);
            
            plot_data_filename = [base_rad, '_plot_data.mat'];
            m = matfile(plot_data_filename, 'Writable', true);
            m.A = A_noin;
            m.coords_full = coords_new;
            m.color_matrix = color_matrix;
            m.communitylayer = communitylayer;
            m.communitysymbol = communitysymbol;
            fprintf('    Full plotting data saved to: %s\n', plot_data_filename);
        end
    end
end

fprintf('\n=== %s finished ===\n', mfilename);
end
end

function coords_full = add_leaves_simple(x_full, coords_core, core_idx, radial_all)
    % x_full      : full adjacency matrix (N x N)
    % coords_core : core coordinates (N_core x 2) – only angles are used
    % core_idx    : indices of core nodes in the full network
    % radial_all  : precomputed radial coordinates for all nodes (N x 1)
    % coords_full : full coordinates (N x 2)

    N = size(x_full, 1);
    degree = sum(x_full > 0, 2);
    
    % ---- 1. Set radial coordinates from the precomputed vector ----
    coords_full = zeros(N, 2);
    coords_full(:, 2) = radial_all;
    
    % ---- 2. Assign core angles (preserve from embedding) ----
    coords_full(core_idx, 1) = coords_core(:, 1);
    
    % ---- 3. Nearest neighbour indices among core nodes (based on core angles) ----
    core_angles = coords_core(:, 1);
    n_core = length(core_angles);
    nearest_neighbor_idx = zeros(n_core, 1);
    for i = 1:n_core
        ang_dist = abs(core_angles - core_angles(i));
        ang_dist = min(ang_dist, 2*pi - ang_dist);  % circular distance
        ang_dist(i) = Inf;
        [~, nearest] = min(ang_dist);
        nearest_neighbor_idx(i) = nearest;
    end
    
    % Map core nodes to positions in the core list
    core_pos = zeros(N, 1);
    core_pos(core_idx) = 1:n_core;
    
    % ---- 4. Assign leaf angles using midpoint rule ----
    leaf_idx = find(degree == 1);
    for i = 1:length(leaf_idx)
        leaf = leaf_idx(i);
        parent = find(x_full(leaf, :));
        if isempty(parent), continue; end
        parent_pos = core_pos(parent);
        nn_pos = nearest_neighbor_idx(parent_pos);
        ang_parent = coords_full(parent, 1);
        ang_nn = coords_full(core_idx(nn_pos), 1);
        coords_full(leaf, 1) = angular_midpoint(ang_parent, ang_nn);
    end
    
    % ---- 5. Adjust duplicate angles ----
    coords_full(:, 1) = adjust_duplicates(coords_full(:, 1));
end


function midpoint = angular_midpoint(theta1, theta2)
    % Ensure theta1 and theta2 are within [0, 2*pi)
    theta1 = mod(theta1, 2*pi);
    theta2 = mod(theta2, 2*pi);
    
    % Calculate the direct angular distance between theta1 and theta2
    delta_theta = mod(theta2 - theta1, 2*pi);
    
    % Adjust for angular wrapping (choose the shorter distance)
    if delta_theta > pi
        delta_theta = delta_theta - 2*pi;
    end
    
    % Calculate the midpoint (halfway along the shorter angular distance)
    midpoint = mod(theta1 + delta_theta / 2, 2*pi);
end

% -------------------------------------------------------------------------
% Radial computation functions (from coalescent_embedding)
% -------------------------------------------------------------------------
function radial = set_radial_coordinates_d(x)
    % degree‑based radial coordinates
    n = size(x,1);
    deg = full(sum(x>0,1))';   % column vector
    if all(deg == deg(1))
        error('All nodes have the same degree – cannot fit power‑law.');
    end
    
    % Fit power‑law degree distribution
    gamma_range = 1.01:0.01:10.00;
    small_size_limit = 100;
    if length(deg) < small_size_limit
        gamma = plfit(deg, 'finite', 'range', gamma_range);
    else
        gamma = plfit(deg, 'range', gamma_range);
    end
    
    % Validate gamma
    if isempty(gamma) || ~isscalar(gamma) || ~isfinite(gamma)
        error('plfit returned an invalid gamma value.');
    end
    
    beta_param = 1 / (gamma - 1);   % renamed from beta
    
    % Sort nodes by decreasing degree
    [~, idx] = sort(deg, 'descend');
    
    % Compute radial coordinates
    radial = zeros(n,1);
    radial(idx) = max(0, 2*beta_param*log(1:n) + 2*(1-beta_param)*log(n));
end

function [radial_coordinates, gamma] = set_radial_coordinates_1_exact(xw)
    n = size(xw,1);
    strength = full(sum(xw,1))';
    
    % ... (power‑law fit same as before) ...
    if all(strength == strength(1))
        error('All the nodes have the same degree, the degree distribution cannot fit a power‑law.');
    end
    gamma_range = 1.01:0.01:10.00;
    small_size_limit = 100;
    if length(strength) < small_size_limit
        gamma = plfit(strength, 'finite', 'range', gamma_range);
    else
        gamma = plfit(strength, 'range', gamma_range);
    end
    beta = 1 / (gamma - 1);
    
    % ---------- Modified sorting and grouping ----------
    [strength_sorted, sort_idx] = sort(strength, 'descend');
    
    % Pre‑compute radial coordinates for all ranks (1..n)
    radial_by_rank = max(0, 2*beta*log(1:n) + 2*(1-beta)*log(n));
    
    % Group nodes with identical strength
    radial_coordinates = zeros(n,1);
    i = 1;
    while i <= n
        % Find all indices with the same strength
        j = i;
        while j < n && strength_sorted(j+1) == strength_sorted(i)
            j = j + 1;
        end
        % For this group of equal strengths, assign the same radius
        % (choose the radius at the median rank of the group)
        median_rank = round((i + j)/2);
        group_radius = radial_by_rank(median_rank);
        
        % Assign to all nodes in this group
        for k = i:j
            radial_coordinates(sort_idx(k)) = group_radius;
        end
        
        i = j + 1;
    end
end


function [radial_coordinates, gamma] = set_radial_coordinates_1_power(xw)
% Substistute the degree with the node strength based on the
% pre-weithing method

n = size(xw,1);
deg = full(sum(xw,1));
if all(deg == deg(1))
   error('All the nodes have the same degree, the degree distribution cannot fit a power-law.'); 
end

% fit power-law degree distribution
gamma_range = 1.01:0.01:10.00;
small_size_limit = 100;
if length(deg) < small_size_limit
    gamma = plfit(deg, 'finite', 'range', gamma_range);
else
    gamma = plfit(deg, 'range', gamma_range);
end
beta = 1 / (gamma - 1);
% sort nodes by decreasing degree
[~,idx] = sort(deg, 'descend');

% for beta > 1 (gamma < 2) some radial coordinates are negative
radial_coordinates = zeros(1, n);
radial_coordinates(idx) = max(0, 2*beta*log(1:n) + 2*(1-beta)*log(n));
end

function radial = set_radial_coordinates_2(x, xw)
    % radial type 2: fit power‑law on degree (x), sort by strength (xw)
    n = size(x,1);
    deg = full(sum(x>0,1))';
    str = full(sum(xw,1))';   % node strength from pre‑weighted matrix
    
    if all(deg == deg(1))
        error('All nodes have the same degree – cannot fit power‑law.');
    end
    
    % Fit power‑law on degree
    gamma_range = 1.01:0.01:10.00;
    small_size_limit = 100;
    if length(deg) < small_size_limit
        gamma = plfit(deg, 'finite', 'range', gamma_range);
    else
        gamma = plfit(deg, 'range', gamma_range);
    end
    
    % Validate gamma
    if isempty(gamma) || ~isscalar(gamma) || ~isfinite(gamma)
        error('plfit returned an invalid gamma value.');
    end
    
    beta_param = 1 / (gamma - 1);   % renamed from beta
    
    % Sort by decreasing strength
    [~, idx] = sort(str, 'descend');
    
    radial = zeros(n,1);
    radial(idx) = max(0, 2*beta_param*log(1:n) + 2*(1-beta_param)*log(n));
end


function radial = set_radial_coordinates_3(x)
    % node betweenness based radial coordinates
    n = size(x,1);
    
    % Compute node betweenness centrality for the full network
    % (assumes function betweenness_centrality exists and returns [nodeBC, edgeBC])
    [node_bc, ~] = betweenness_centrality(sparse(x));
    node_bc = node_bc(:);                 % ensure column vector
    
    % Add 1 to avoid zeros (leaves often have zero betweenness)
    node_bc = node_bc + 1;
    
    if all(node_bc == node_bc(1))
        error('All nodes have the same betweenness – cannot fit power‑law.');
    end
    
    % Fit power‑law to the node betweenness distribution
    gamma_range = 1.01:0.01:10.00;
    small_size_limit = 100;
    if length(node_bc) < small_size_limit
        gamma = plfit(node_bc, 'finite', 'range', gamma_range);
    else
        gamma = plfit(node_bc, 'range', gamma_range);
    end
    
    if isempty(gamma) || ~isscalar(gamma) || ~isfinite(gamma)
        error('plfit returned an invalid gamma value.');
    end
    
    beta_param = 1 / (gamma - 1);
    
    % Sort nodes by decreasing betweenness
    [~, idx] = sort(node_bc, 'descend');
    
    % Compute radial coordinates using the same formula as degree‑based version
    radial = zeros(n,1);
    radial(idx) = max(0, 2*beta_param*log(1:n) + 2*(1-beta_param)*log(n));
end


function xw = compute_preweighted(x, method)
    % Re‑create the pre‑weighted matrix using the specified method
    % (only needed for radial types that require xw)
    if strcmp(method, 'reverse')
        xw = reverse_weights(x);
    elseif strcmp(method, 'RA1')
        xw = RA1_weighting(double(x>0));
    elseif strcmp(method, 'RA2')
        xw = RA2_weighting(double(x>0));
    elseif strcmp(method, 'EBC')
        xw = EBC_weighting(double(x>0));
    elseif strcmp(method, 'nEBC')
        xw = nEBC_weighting(double(x>0));
    else
        error('Unknown pre‑weighting method: %s', method);
    end
end

function angles = adjust_duplicates(angles, tol)
    if nargin < 2, tol = 1e-10; end
    angles = mod(angles, 2*pi);
    [sorted, idx] = sort(angles);
    for i = 2:length(sorted)
        if sorted(i) - sorted(i-1) < tol
            sorted(i) = sorted(i-1) + tol;
        end
    end
    % Ensure still within [0,2π)
    sorted = mod(sorted, 2*pi);
    angles(idx) = sorted;
end

function x_EBC = EBC_weighting(x)

[~,x_EBC] = betweenness_centrality(sparse(x));
end

function x_EBC = nEBC_weighting(x)

[~,x_EBC] = betweenness_centrality(sparse(x));
n=size(x,1);
x_EBC = x_EBC/( (n-1) * (n-2) )/2;
end

function [alpha, xmin, L]=plfit(x, varargin)
% PLFIT fits a power-law distributional model to data.
%    Source: http://www.santafe.edu/~aaronc/powerlaws/
% 
%    PLFIT(x) estimates x_min and alpha according to the goodness-of-fit
%    based method described in Clauset, Shalizi, Newman (2007). x is a 
%    vector of observations of some quantity to which we wish to fit the 
%    power-law distribution p(x) ~ x^-alpha for x >= xmin.
%    PLFIT automatically detects whether x is composed of real or integer
%    values, and applies the appropriate method. For discrete data, if
%    min(x) > 1000, PLFIT uses the continuous approximation, which is 
%    a reliable in this regime.
%   
%    The fitting procedure works as follows:
%    1) For each possible choice of x_min, we estimate alpha via the 
%       method of maximum likelihood, and calculate the Kolmogorov-Smirnov
%       goodness-of-fit statistic D.
%    2) We then select as our estimate of x_min, the value that gives the
%       minimum value D over all values of x_min.
%
%    Note that this procedure gives no estimate of the uncertainty of the 
%    fitted parameters, nor of the validity of the fit.
%
%    Example:
%       x = (1-rand(10000,1)).^(-1/(2.5-1));
%       [alpha, xmin, L] = plfit(x);
%
%    The output 'alpha' is the maximum likelihood estimate of the scaling
%    exponent, 'xmin' is the estimate of the lower bound of the power-law
%    behavior, and L is the log-likelihood of the data x>=xmin under the
%    fitted power law.
%    
%    For more information, try 'type plfit'
%
%    See also PLVAR, PLPVA

% Version 1.0    (2007 May)
% Version 1.0.2  (2007 September)
% Version 1.0.3  (2007 September)
% Version 1.0.4  (2008 January)
% Version 1.0.5  (2008 March)
% Version 1.0.6  (2008 July)
% Version 1.0.7  (2008 October)
% Version 1.0.8  (2009 February)
% Version 1.0.9  (2009 October)
% Version 1.0.10 (2010 January)
% Version 1.0.11 (2012 January)
% Copyright (C) 2008-2012 Aaron Clauset (Santa Fe Institute)
% Distributed under GPL 2.0
% http://www.gnu.org/copyleft/gpl.html
% PLFIT comes with ABSOLUTELY NO WARRANTY
% 
% Notes:
% 
% 1. In order to implement the integer-based methods in Matlab, the numeric
%    maximization of the log-likelihood function was used. This requires
%    that we specify the range of scaling parameters considered. We set
%    this range to be [1.50 : 0.01 : 3.50] by default. This vector can be
%    set by the user like so,
%    
%       a = plfit(x,'range',[1.001:0.001:5.001]);
%    
% 2. PLFIT can be told to limit the range of values considered as estimates
%    for xmin in three ways. First, it can be instructed to sample these
%    possible values like so,
%    
%       a = plfit(x,'sample',100);
%    
%    which uses 100 uniformly distributed values on the sorted list of
%    unique values in the data set. Second, it can simply omit all
%    candidates above a hard limit, like so
%    
%       a = plfit(x,'limit',3.4);
%    
%    Finally, it can be forced to use a fixed value, like so
%    
%       a = plfit(x,'xmin',3.4);
%    
%    In the case of discrete data, it rounds the limit to the nearest
%    integer.
% 
% 3. When the input sample size is small (e.g., < 100), the continuous 
%    estimator is slightly biased (toward larger values of alpha). To
%    explicitly use an experimental finite-size correction, call PLFIT like
%    so
%    
%       a = plfit(x,'finite');
%    
%    which does a small-size correction to alpha.
%
% 4. For continuous data, PLFIT can return erroneously large estimates of 
%    alpha when xmin is so large that the number of obs x >= xmin is very 
%    small. To prevent this, we can truncate the search over xmin values 
%    before the finite-size bias becomes significant by calling PLFIT as
%    
%       a = plfit(x,'nosmall');
%    
%    which skips values xmin with finite size bias > 0.1.

vec     = [];
sample  = [];
xminx   = [];
limit   = [];
finite  = false;
nosmall = false;
nowarn  = false;

% parse command-line parameters; trap for bad input
i=1; 
while i<=length(varargin), 
  argok = 1; 
  if ischar(varargin{i}), 
    switch varargin{i},
        case 'range',        vec     = varargin{i+1}; i = i + 1;
        case 'sample',       sample  = varargin{i+1}; i = i + 1;
        case 'limit',        limit   = varargin{i+1}; i = i + 1;
        case 'xmin',         xminx   = varargin{i+1}; i = i + 1;
        case 'finite',       finite  = true;
        case 'nowarn',       nowarn  = true;
        case 'nosmall',      nosmall = true;
        otherwise, argok=0; 
    end
  end
  if ~argok, 
    disp(['(PLFIT) Ignoring invalid argument #' num2str(i+1)]); 
  end
  i = i+1; 
end
if ~isempty(vec) && (~isvector(vec) || min(vec)<=1),
	fprintf('(PLFIT) Error: ''range'' argument must contain a vector; using default.\n');
    vec = [];
end;
if ~isempty(sample) && (~isscalar(sample) || sample<2),
	fprintf('(PLFIT) Error: ''sample'' argument must be a positive integer > 1; using default.\n');
    sample = [];
end;
if ~isempty(limit) && (~isscalar(limit) || limit<min(x)),
	fprintf('(PLFIT) Error: ''limit'' argument must be a positive value >= 1; using default.\n');
    limit = [];
end;
if ~isempty(xminx) && (~isscalar(xminx) || xminx>=max(x)),
	fprintf('(PLFIT) Error: ''xmin'' argument must be a positive value < max(x); using default behavior.\n');
    xminx = [];
end;

% reshape input vector
x = reshape(x,numel(x),1);

% select method (discrete or continuous) for fitting
if     isempty(setdiff(x,floor(x))), f_dattype = 'INTS';
elseif isreal(x),    f_dattype = 'REAL';
else                 f_dattype = 'UNKN';
end;
if strcmp(f_dattype,'INTS') && min(x) > 1000 && length(x)>100,
    f_dattype = 'REAL';
end;

% estimate xmin and alpha, accordingly
switch f_dattype,
    
    case 'REAL',
        xmins = unique(x);
        xmins = xmins(1:end-1);
        if ~isempty(xminx),
            xmins = xmins(find(xmins>=xminx,1,'first'));
        end;
        if ~isempty(limit),
            xmins(xmins>limit) = [];
        end;
        if ~isempty(sample),
            xmins = xmins(unique(round(linspace(1,length(xmins),sample))));
        end;
        dat   = zeros(size(xmins));
        z     = sort(x);
        for xm=1:length(xmins)
            xmin = xmins(xm);
            z    = z(z>=xmin); 
            n    = length(z);
            % estimate alpha using direct MLE
            a    = n ./ sum( log(z./xmin) );
            if nosmall,
                if (a-1)/sqrt(n) > 0.1
                    dat(xm:end) = [];
                    xm = length(xmins)+1; %#ok<FXSET,NASGU>
                    break;
                end;
            end;
            % compute KS statistic
            cx   = (0:n-1)'./n;
            cf   = 1-(xmin./z).^a;
            dat(xm) = max( abs(cf-cx) );
        end;
        D     = min(dat);
        xmin  = xmins(find(dat<=D,1,'first'));
        z     = x(x>=xmin);
        n     = length(z); 
        alpha = 1 + n ./ sum( log(z./xmin) );
        if finite, alpha = alpha*(n-1)/n+1/n; end; % finite-size correction
        if n < 50 && ~finite && ~nowarn,
%             fprintf('(PLFIT) Warning: finite-size bias may be present.\n');
        end;
        L = n*log((alpha-1)/xmin) - alpha.*sum(log(z./xmin));

    case 'INTS',
        
        if isempty(vec),
            vec  = (1.50:0.01:3.50);    % covers range of most practical 
        end;                            % scaling parameters
        zvec = zeta(vec);

        xmins = unique(x);
        xmins = xmins(1:end-1);
        if ~isempty(xminx),
            xmins = xmins(find(xmins>=xminx,1,'first'));
        end;
        if ~isempty(limit),
            limit = round(limit);
            xmins(xmins>limit) = [];
        end;
        if ~isempty(sample),
            xmins = xmins(unique(round(linspace(1,length(xmins),sample))));
        end;
        if isempty(xmins)
            fprintf('(PLFIT) Error: x must contain at least two unique values.\n');
            alpha = NaN; xmin = x(1); D = NaN; %#ok<NASGU>
            return;
        end;
        xmax   = max(x);
        dat    = zeros(length(xmins),2);
        z      = x;
        fcatch = 0;

        for xm=1:length(xmins)
            xmin = xmins(xm);
            z    = z(z>=xmin);
            n    = length(z);
            % estimate alpha via direct maximization of likelihood function
            if fcatch==0
                try
                    % vectorized version of numerical calculation
                    zdiff = sum( repmat((1:xmin-1)',1,length(vec)).^-repmat(vec,xmin-1,1) ,1);
                    L = -vec.*sum(log(z)) - n.*log(zvec - zdiff);
                catch
                    % catch: force loop to default to iterative version for
                    % remainder of the search
                    fcatch = 1;
                end;
            end;
            if fcatch==1
                % force iterative calculation (more memory efficient, but 
                % can be slower)
                L       = -Inf*ones(size(vec));
                slogz   = sum(log(z));
                xminvec = (1:xmin-1);
                for k=1:length(vec)
                    L(k) = -vec(k)*slogz - n*log(zvec(k) - sum(xminvec.^-vec(k)));
                end
            end;
            [Y,I] = max(L); %#ok<ASGLU>
            % compute KS statistic
            fit = cumsum((((xmin:xmax).^-vec(I)))./ (zvec(I) - sum((1:xmin-1).^-vec(I))));
            cdi = cumsum(hist(z,xmin:xmax)./n);
            dat(xm,:) = [max(abs( fit - cdi )) vec(I)];
        end
        % select the index for the minimum value of D
        [D,I] = min(dat(:,1)); %#ok<ASGLU>
        xmin  = xmins(I);
        z     = x(x>=xmin);
        n     = length(z);
        alpha = dat(I,2);
        if finite, alpha = alpha*(n-1)/n+1/n; end; % finite-size correction
        if n < 50 && ~finite && ~nowarn,
%             fprintf('(PLFIT) Warning: finite-size bias may be present.\n');
        end;
        L     = -alpha*sum(log(z)) - n*log(zvec(find(vec<=alpha,1,'last')) - sum((1:xmin-1).^-alpha));

    otherwise,
        fprintf('(PLFIT) Error: x must contain only reals or only integers.\n');
        alpha = [];
        xmin  = [];
        L     = [];
        return;
end
end
