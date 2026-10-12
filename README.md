# Network Neuromorphic AI

This repository contains the code and analysis material for the neuromorphic
neural-network study. The project is organized into three folders:

- [`network`](network/) contains the Python/PyTorch model, training and
  evaluation code, saved weights, and example results.
- [`silencing`](silencing/) contains the component-silencing (ablation) results,
  their description, and the corresponding plot and methodology document.
- [`embedding`](embedding/) contains the MATLAB workflow for building the
  neuromorphic topology, calculating network measures, computing its
  hyperbolic embedding, and producing the network visualization.

## Simple workflow

1. Use `network` to train or evaluate the neural-network model.
2. Use the data in `silencing` to examine how removing network components
   affects accuracy.
3. Use `embedding` to reconstruct and analyze the network topology in
   hyperbolic space.

Each folder has its own README with the relevant setup and usage details:

- [Network instructions](network/README.md)
- [Silencing data description](silencing/README.md)
- [Embedding instructions](embedding/README.md)
