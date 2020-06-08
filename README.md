# MemoryEfficientStableLDS
Codebase associated with paper "Learning Memory-Efficient Stable Linear Dynamical Systems for Prediction and Control"

## Getting data
To get the datasets, read the instructions in the `data` directory. The data for the Franka Emika Panda experiments is contained in the `FrankaLDS` directory. 

## Data preparation

To prepare the datasets for the UCLA, UCSD and DynTex benchmarks, follow the instructions in the `prepare_data` directory.

## Learning LDS for UCLA, UCSD and DynTex

To reproduce our results for the UCLA, UCSD and DynTex benchmarks, you will need to run the `ReconstructImage.m` file. **NOTE**: you will need to set the configuration options at the top of the file so that it can work on your particular system.

## Learning and control on Franka Emika Panda
