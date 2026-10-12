function [color_matrix_sampled, communitysymbol_sampled] = apply_d2_group_coloring( ...
    selected_full, adj_full, node_ranges, color_matrix_sampled, communitysymbol_sampled)

% Recolor nodes based on D2 grouping and set layer-specific fill style
% Layer 1 -> filled
% Layer 2 -> unfilled
% D2 groups:
%   D2(*,1) = red
%   D2(*,2) = orange
%   D2(*,3) = green
%   D2(*,4) = blue
%
% Color is propagated to SO1, S2, and D2 nodes.
% Optionally can be extended to D1 and S1 later.

new_color_matrix = color_matrix_sampled;

Nsample = length(selected_full);

% full index -> sampled position map
full_to_sample = containers.Map('KeyType','double','ValueType','double');
for ii = 1:Nsample
    full_to_sample(selected_full(ii)) = ii;
end


% -------------------- color definitions --------------------
c1 = [0.86 0.31 0.35];
c2 = [0.95 0.62 0.20];
c3 = [0.39 0.72 0.34];
c4 = [0.20 0.52 0.78];

nL1Neurons = 500;
nL2Neurons = 10;
nL2Dend = 4;
nL1Dend = 9;

% S1 block sizes connected to each D1 branch
s1_block_sizes = [1 1 1 1 1 1 1 1 1];
total_s1_per_neuron = sum(s1_block_sizes);


% -------------------- propagate SO1 color to D1 --------------------


for j = 1:nL1Neurons

    % same group color as SO1(j)
    if j <= 125
        col = c1;
    elseif j <= 250
        col = c2;
    elseif j <= 375
        col = c3;
    else
        col = c4;
    end

    % color all D1(j,1:9) with the same color
    for k = 1:nL1Dend
        idx_d1_full = node_ranges.D1(1) - 1 + (j-1)*nL1Dend + k;
        if isKey(full_to_sample, idx_d1_full)
            p = full_to_sample(idx_d1_full);
            new_color_matrix(p,:) = col;
        end
 

  % Connected S1 color
        nS1_this = s1_block_sizes(k);
        offset_within_neuron = sum(s1_block_sizes(1:k-1));
        offset_before_neuron = (j-1) * total_s1_per_neuron;

        for ii = 1:nS1_this
            idx_s1_full = node_ranges.S1(1) - 1 + offset_before_neuron + offset_within_neuron + ii;
            if isKey(full_to_sample, idx_s1_full)
                p = full_to_sample(idx_s1_full);
                new_color_matrix(p,:) = col;
            end
        end
    end
end

% -------------------- propagate D2 group color --------------------
for m = 1:nL2Neurons
    for j = 1:nL1Neurons

        if j <= 125
            n = 1; col = c1;
        elseif j <= 250
            n = 2; col = c2;
        elseif j <= 375
            n = 3; col = c3;
        else
            n = 4; col = c4;
        end

        idx_so1_full = node_ranges.SO1(1) - 1 + j;
        idx_s2_full  = node_ranges.S2(1)  - 1 + (m-1)*nL1Neurons + j;
        idx_d2_full  = node_ranges.D2(1)  - 1 + (m-1)*nL2Dend + n;

        if isKey(full_to_sample, idx_so1_full)
            p = full_to_sample(idx_so1_full);
            new_color_matrix(p,:) = col;
        end

        if isKey(full_to_sample, idx_s2_full)
            p = full_to_sample(idx_s2_full);
            new_color_matrix(p,:) = col;
        end

        if isKey(full_to_sample, idx_d2_full)
            p = full_to_sample(idx_d2_full);
            new_color_matrix(p,:) = col;
        end
    end
end

% -------------------- overwrite outputs --------------------
color_matrix_sampled = new_color_matrix;

end