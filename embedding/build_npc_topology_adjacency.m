% build_npc_topology_adjacency.m
% Build sparse binary adjacency matrix for the NPC-expanded topology
% described for the SVHN -> L1 -> L2 network.
%
% Output:
%   - npc_topology_adjacency.mat
%     containing:
%       A           : sparse binary adjacency matrix
%       node_ranges : struct with index ranges for each node type
%       meta        : struct with topology metadata
%
% Notes:
%   - Synapses (S1, S2) are treated as nodes.
%   - Edge directions are ignored; adjacency is undirected and binary.
%   - Weights are ignored; connected = 1, otherwise 0.

clear; clc;

%% -------------------- node counts --------------------
nInput = 9;           % total input nodes (3x3 grid)
% Pattern: (IS IC IS) (IS IC IS) (IS IC IS) -> row-major order
% IC indices: 2, 5, 8  (central column)
% IS indices: 1,3,4,6,7,9 (side positions)
nL1Neurons = 500;
nL1Dend = 9;
nL2Neurons = 10;
nL2Dend = 4;

nS1  = nInput * nL1Neurons;   % 9 x 500
nD1  = nL1Neurons * nL1Dend;  % 500 x 9
nSO1 = nL1Neurons;            % 500
nS2  = nL1Neurons * nL2Neurons; % 500 x 10
nD2  = nL2Neurons * nL2Dend;    % 10 x 4
nSO2 = nL2Neurons;              % 10

%% -------------------- global index ranges --------------------
start_Input = 1;
end_Input   = start_Input + nInput - 1;

start_S1 = end_Input + 1;
end_S1   = start_S1 + nS1 - 1;

start_D1 = end_S1 + 1;
end_D1   = start_D1 + nD1 - 1;

start_SO1 = end_D1 + 1;
end_SO1   = start_SO1 + nSO1 - 1;

start_S2 = end_SO1 + 1;
end_S2   = start_S2 + nS2 - 1;

start_D2 = end_S2 + 1;
end_D2   = start_D2 + nD2 - 1;

start_SO2 = end_D2 + 1;
end_SO2   = start_SO2 + nSO2 - 1;

N = end_SO2;

%% -------------------- helper mapping --------------------
% L2: SO1 block -> dendrite block
n_of_j = @(j) ...
    (j<=125) * 1 + ...
    (j>=126 & j<=250) * 2 + ...
    (j>=251 & j<=375) * 3 + ...
    (j>=376 & j<=500) * 4;

%% -------------------- index functions --------------------
idx_I   = @(i) start_Input - 1 + i;
idx_S1  = @(i,j) start_S1  - 1 + (j-1)*nInput + i;
idx_D1  = @(j,k) start_D1  - 1 + (j-1)*nL1Dend + k;
idx_SO1 = @(j)   start_SO1 - 1 + j;
idx_S2  = @(j,m) start_S2  - 1 + (m-1)*nL1Neurons + j;
idx_D2  = @(m,n) start_D2  - 1 + (m-1)*nL2Dend + n;
idx_SO2 = @(m)   start_SO2 - 1 + m;

%% -------------------- expected edge count --------------------
% Undirected logical edges:
% L1: I-S1 + S1-D1 + D1-SO1
% L2: SO1-S2 + S2-D2 + D2-SO2
E_undirected = ...
    (nInput * nL1Neurons) + ...
    (nInput * nL1Neurons) + ...
    (nL1Neurons * nL1Dend) + ...
    (nL1Neurons * nL2Neurons) + ...
    (nL1Neurons * nL2Neurons) + ...
    (nL2Neurons * nL2Dend);

% Because we store symmetric adjacency explicitly:
E_symmetric_entries = 2 * E_undirected;

rows = zeros(E_symmetric_entries,1,'uint32');
cols = zeros(E_symmetric_entries,1,'uint32');
ptr = uint32(1);

%% -------------------- build L1 --------------------
for j = 1:nL1Neurons
    % Input -- S1 and S1 -- D1
        for i = 1:nInput
        k = i;   % each input maps directly to dendrite block i

        a = idx_I(i);
        b = idx_S1(i,j);
        c = idx_D1(j,k);

        % I -- S1
        rows(ptr) = a; cols(ptr) = b; ptr = ptr + 1;
        rows(ptr) = b; cols(ptr) = a; ptr = ptr + 1;

        % S1 -- D1
        rows(ptr) = b; cols(ptr) = c; ptr = ptr + 1;
        rows(ptr) = c; cols(ptr) = b; ptr = ptr + 1;
    end

    % D1 -- SO1
    for k = 1:nL1Dend
        a = idx_D1(j,k);
        b = idx_SO1(j);

        rows(ptr) = a; cols(ptr) = b; ptr = ptr + 1;
        rows(ptr) = b; cols(ptr) = a; ptr = ptr + 1;
    end
end

%% -------------------- build L2 --------------------
for m = 1:nL2Neurons
    % SO1 -- S2 and S2 -- D2
    for j = 1:nL1Neurons
        n = n_of_j(j);

        a = idx_SO1(j);
        b = idx_S2(j,m);
        c = idx_D2(m,n);

        % SO1 -- S2
        rows(ptr) = a; cols(ptr) = b; ptr = ptr + 1;
        rows(ptr) = b; cols(ptr) = a; ptr = ptr + 1;

        % S2 -- D2
        rows(ptr) = b; cols(ptr) = c; ptr = ptr + 1;
        rows(ptr) = c; cols(ptr) = b; ptr = ptr + 1;
    end

    % D2 -- SO2
    for n = 1:nL2Dend
        a = idx_D2(m,n);
        b = idx_SO2(m);

        rows(ptr) = a; cols(ptr) = b; ptr = ptr + 1;
        rows(ptr) = b; cols(ptr) = a; ptr = ptr + 1;
    end
end

% trim in case of mismatch
rows = double(rows(1:double(ptr)-1));
cols = double(cols(1:double(ptr)-1));

%% -------------------- sparse adjacency --------------------
A = sparse(rows, cols, 1, N, N);
A = spones(A);  % binary sparse adjacency

%% -------------------- metadata --------------------
node_ranges = struct();
node_ranges.Input = [start_Input, end_Input];
node_ranges.S1    = [start_S1, end_S1];
node_ranges.D1    = [start_D1, end_D1];
node_ranges.SO1   = [start_SO1, end_SO1];
node_ranges.S2    = [start_S2, end_S2];
node_ranges.D2    = [start_D2, end_D2];
node_ranges.SO2   = [start_SO2, end_SO2];

% Split Input nodes into IC (central) and IS (side)
% 3x3 grid: row-major order
% IC indices: 2,5,8 (central column)
% IS indices: 1,3,4,6,7,9
ic_positions = [2,5,8];
is_positions = setdiff(1:nInput, ic_positions);

% Global indices
ic_global = start_Input + ic_positions - 1;
is_global = start_Input + is_positions - 1;

% Store as arrays (not contiguous ranges)
node_ranges.Input_IC = ic_global;   % vector of 3 indices
node_ranges.Input_IS = is_global;   % vector of 6 indices

meta = struct();
meta.total_nodes = N;
meta.total_nonzeros = nnz(A);
meta.is_symmetric = issymmetric(A);
meta.nInput = nInput;
meta.nL1Neurons = nL1Neurons;
meta.nL1Dend = nL1Dend;
meta.nL2Neurons = nL2Neurons;
meta.nL2Dend = nL2Dend;
meta.description = 'Sparse binary undirected NPC-expanded topology adjacency';

%% -------------------- optional sanity checks --------------------
% Degree distribution for all node types including split Input
% -------------------------------------------------------------------------
% Degree distribution per node type (including separate IC and IS)
% -------------------------------------------------------------------------
deg = full(sum(A, 2));

% Define node types and their indices
type_info = struct();
type_info.Input_IC = node_ranges.Input_IC;
type_info.Input_IS = node_ranges.Input_IS;
type_info.S1    = node_ranges.S1(1):node_ranges.S1(2);
type_info.D1    = node_ranges.D1(1):node_ranges.D1(2);
type_info.SO1   = node_ranges.SO1(1):node_ranges.SO1(2);
type_info.S2    = node_ranges.S2(1):node_ranges.S2(2);
type_info.D2    = node_ranges.D2(1):node_ranges.D2(2);
type_info.SO2   = node_ranges.SO2(1):node_ranges.SO2(2);

type_names = fieldnames(type_info);

fprintf('\n=== Degree distribution per node type ===\n');
for t = 1:length(type_names)
    name = type_names{t};
    indices = type_info.(name);
    degs = deg(indices);
    fprintf('%s (%d nodes):\n', name, length(indices));
    unique_degs = unique(degs);
    for d = unique_degs'
        fprintf('  degree %d: %d node(s)\n', d, sum(degs == d));
    end
    fprintf('\n');
end
fprintf('=== End of degree distribution ===\n');

save('npc_topology_adjacency.mat', 'A', 'node_ranges', 'meta', '-v7.3');
fprintf('Saved: npc_topology_adjacency.mat\n');

%% Remove Input nodes and save no‑input version
fprintf('\n--- Removing Input nodes for no-input version ---\n');
input_idx = node_ranges.Input(1):node_ranges.Input(2);   % all Input nodes (9)

% Remove rows and columns from adjacency
A_noin = A;
A_noin(input_idx, :) = [];
A_noin(:, input_idx) = [];

% Adjust node ranges for the remaining types (shift indices down by nInput)
nInput = length(input_idx);
node_ranges_noin = struct();
if isfield(node_ranges, 'S1')
    node_ranges_noin.S1 = node_ranges.S1 - nInput;
end
if isfield(node_ranges, 'D1')
    node_ranges_noin.D1 = node_ranges.D1 - nInput;
end
if isfield(node_ranges, 'SO1')
    node_ranges_noin.SO1 = node_ranges.SO1 - nInput;
end
if isfield(node_ranges, 'S2')
    node_ranges_noin.S2 = node_ranges.S2 - nInput;
end
if isfield(node_ranges, 'D2')
    node_ranges_noin.D2 = node_ranges.D2 - nInput;
end
if isfield(node_ranges, 'SO2')
    node_ranges_noin.SO2 = node_ranges.SO2 - nInput;
end

% Also update Input_IC/Input_IS? They are removed, so we don't include them.
% We could also store the removed input indices if needed, but not necessary.

% Update metadata
meta_noin = meta;
meta_noin.total_nodes = size(A_noin, 1);
meta_noin.nInput = 0;
meta_noin.description = [meta.description, ' (Input nodes removed)'];

% Save
save('npc_topology_adjacency-noin.mat', 'A_noin', 'node_ranges_noin', 'meta_noin', '-v7.3');
fprintf('Saved: npc_topology_adjacency-noin.mat\n');
