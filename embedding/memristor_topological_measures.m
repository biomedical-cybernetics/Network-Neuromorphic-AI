function memristor_topological_measures

filename = "npc_topology_adjacency-noin";

load(filename + ".mat", 'A_noin');

adj = A_noin;

requested_measures = {'N', 'E', 'density', 'avgdeg', 'clustering', ...
    'powerlaw_gamma_deg', 'powerlaw_gamma_bc'};
topological_measures = compute_topological_measures(adj, requested_measures, 0);

T = struct2table(topological_measures, 'AsArray', true);

writetable(T, filename + "_topological_measures.csv");
