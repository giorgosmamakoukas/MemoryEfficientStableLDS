# MemoryEfficientStableLDS
Codebase for replicating experiments in the NeurIPS 2020 [paper](https://arxiv.org/abs/2006.03937) "Memory-Efficient Learning of Stable Linear Dynamical Systems for Prediction and Control" by [Giorgos Mamakoukas](https://gmamakoukas.com/), [Orest Xherija](https://github.com/orestxherija) and [Todd D. Murphey](https://murpheylab.github.io/people/toddmurphey.html).

## Getting data
To get the datasets, read the instructions in the `data` directory. The data for the Franka Emika Panda experiments is contained in the `FrankaLDS` directory. 

## Data preparation

To prepare the datasets for the UCLA, UCSD and DynTex benchmarks, follow the instructions in the `prepare_data` directory.

## Learning LDS for UCLA, UCSD and DynTex

To reproduce our results for the UCLA, UCSD and DynTex benchmarks, you will need to run the `ReconstructImage.m` file. **NOTE**: you will need to set the configuration options at the top of the file so that it can work on your particular system.

## Learning and control on Franka Emika Panda

For our results of Franka Emika Panda, consult the `FrankaLDS` directroy.
