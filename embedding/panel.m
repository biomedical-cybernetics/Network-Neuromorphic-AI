function panel
fprintf('=== Starting %s ===\n', mfilename);
orig_adj_file = 'npc_topology_adjacency-noin.mat';

load(orig_adj_file, 'A_noin', 'node_ranges_noin');
A = A_noin;
node_ranges = node_ranges_noin;

adj_full = A; N_full = size(adj_full, 1);


coords_files = dir('*_coords.csv');
if isempty(coords_files)
    warning('No files matching *_coords.csv found.');
    return;
end

for f = 1:length(coords_files)
    coords_file = coords_files(f).name;

    base_name = erase(coords_file, '_coords.csv');
    plot_data_file = [base_name, '_plot_data.mat']; 

    if ~exist(plot_data_file, 'file')
        warning('Plot data file %s not found, skipping %s', plot_data_file, coords_file);
        continue;
    end

    fprintf('\n========================================\n');
    fprintf('Processing dataset: %s\n', base_name);
    fprintf('----------------------------------------\n');


    fprintf('Full network: %d nodes\n', N_full);

    fprintf('Loading coordinates from plot data: %s\n', plot_data_file);
    coords_full = readmatrix(coords_file);   % N x 2 (theta, radius) after Input removal

    fprintf('Loading attributes from: %s\n', plot_data_file);
    load(plot_data_file, 'color_matrix', 'communitylayer', 'communitysymbol');

    total_nodes_rem = size(coords_full, 1);
    fprintf('Total nodes after Input removal: %d\n', total_nodes_rem);
    valid_coord = isfinite(coords_full(:,1)) & isfinite(coords_full(:,2));
    valid_coord_idx = find(valid_coord);
    fprintf('Nodes with valid coordinates: %d out of %d\n', length(valid_coord_idx), size(coords_full,1));

    valid_full_all = valid_coord_idx;  
    fprintf('Total valid nodes in full adjacency: %d\n', length(valid_full_all));

    type_valid_full = struct();
    type_names = fieldnames(node_ranges);
    for i = 1:length(type_names)
        t = type_names{i};
        r = node_ranges.(t); 
        in_range = (valid_full_all >= r(1)) & (valid_full_all <= r(2));
        type_valid_full.(t) = valid_full_all(in_range);
        fprintf('%s: total valid nodes %d\n', t, length(type_valid_full.(t)));
    end

    sample_counts = struct();
    sample_counts.S1    = 450;
    sample_counts.D1    = 450;
    sample_counts.SO1   = 100;
    sample_counts.S2    = 500;
    sample_counts.D2    = 40;
    sample_counts.SO2   = 10;

    selected_full = [];
    for t = fieldnames(sample_counts)'
        t = t{1};
        if ~isfield(type_valid_full, t), continue; end
        valid_full = type_valid_full.(t);
        total = length(valid_full);
        ns = sample_counts.(t);
        if ns >= total
            take = valid_full;
            fprintf('  %s: taking all %d valid nodes.\n', t, total);
        else
            positions = round(linspace(1, total, ns));
            take = valid_full(positions);
            fprintf('  %s: sampling %d out of %d valid nodes (equidistant).\n', t, ns, total);
        end
        selected_full = [selected_full; take(:)];
    end

    selected_full = sort(unique(selected_full));
    fprintf('Total selected nodes (full indices): %d\n', length(selected_full));

    adj_sampled = adj_full(selected_full, selected_full);
    coords_sampled = coords_full(selected_full, :);
    color_matrix_sampled = color_matrix(selected_full, :);
    communitylayer_sampled = communitylayer(selected_full);
    communitysymbol_sampled = communitysymbol(selected_full);

% Ensure no sampled node is isolated in the sampled subgraph.
isolated = find(sum(adj_sampled, 2) == 0);
while ~isempty(isolated)
    % For each isolated node, add one of its neighbors from the full graph
    for i = 1:length(isolated)
        node = selected_full(isolated(i));  % original full index
        % Find all neighbors of this node in the full graph
        neigh = find(adj_full(node, :));
        % Choose the first neighbor that is not already in the sample
        new_nodes = setdiff(neigh, selected_full);
        if isempty(new_nodes)
            % No new neighbor available – skip (shouldn't happen if full graph is connected)
            continue;
        end
        new_node = new_nodes(1);
        % Add this new node to the sample
        selected_full = [selected_full; new_node];
        % Update all sampled arrays
        adj_sampled = adj_full(selected_full, selected_full);
        coords_sampled = coords_full(selected_full, :);
        color_matrix_sampled = color_matrix(selected_full, :);
        communitylayer_sampled = communitylayer(selected_full);
        communitysymbol_sampled = communitysymbol(selected_full);
    end
    % Recompute isolated nodes after additions
    isolated = find(sum(adj_sampled, 2) == 0);
end
    [color_matrix_sampled, communitysymbol_sampled] = apply_d2_group_coloring( ...
        selected_full, adj_full, node_ranges, color_matrix_sampled, communitysymbol_sampled);


    repr = 'native';

    fprintf('Plotting with node size = radial ...\n');
    figure('Name', sprintf('%s - radial size', base_name), 'Visible', 'on');
    plot_hyperbolic_network(adj_sampled, coords_sampled, repr, ...
        color_matrix_sampled, [], communitysymbol_sampled, communitylayer_sampled, 'radial');
    title(sprintf('%s (node size = full radial)', base_name));
    
    fig_radial = sprintf('%s_radial_size.png', base_name);
    exportgraphics(gcf, fig_radial, 'Resolution', 150);
    fprintf('Saved: %s\n', fig_radial);
    close(gcf);
end
fprintf('\n=== %s finished ===\n', mfilename);
end
