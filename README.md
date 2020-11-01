# Introduction
Codebase for replicating experiments in the NeurIPS 2020 [paper](https://arxiv.org/abs/2006.03937) "Memory-Efficient Learning of Stable Linear Dynamical Systems for Prediction and Control" by [Giorgos Mamakoukas](https://gmamakoukas.com/), [Orest Xherija](https://github.com/orestxherija) and [Todd D. Murphey](https://murpheylab.github.io/people/toddmurphey.html).

The `master` branch of this repository contains the code that we used to generate the results that appear on the paper. In the `python` branch, you will find a Python implementation of the SOC algorithm that we present in our paper, along with instructions on how to run it on your own data.

# Table of contents
1. [Datasets](#datasets)
2. [Data Preparation](#data-preparation)
3. [Dynamical Texture Experiments](#dynamical-texture-experiments)
4. [Franka Emika Panda Experiments](#franka-emika-panda-experiments)
5. [Citing](#citing)
6. [Troubleshooting](#troubleshooting)

## Datasets

To get the datasets used for our experiments, read the instructions in the `data` directory.

## Data Preparation

To prepare the datasets for the UCLA, UCSD and DynTex prediction experiments, follow the instructions in the `prepare_data` directory.

## Dynamical Texture Experiments

To reproduce our results for the UCLA, UCSD and DynTex benchmarks, you will need to run the `TrainDynamicTexture.m` file. 

**NOTE**: you will need to set some configuration options at the top of the `TrainDynamicTexture.m` file so that it can work on your particular system.

## Franka Emika Panda Experiments

To reproduce our results from the simulations and experiments with the Franka Emika Panda robotic arm manipulator, consult the `FrankaLDS` directory.

# Citing

If you find this project useful, consider

- starring this repository ⭐
- watching this repository for updates 
- citing our paper (complete citation available after the publication of the NeurIPS 2020 proceedings)

```
@inproceedings{mamakoukas2020_memEfficientLDS,
  title={Memory-Efficient Learning of Stable Linear Dynamical Systems for Prediction and Control},
  author={Mamakoukas, Giorgos and Xherija, Orest and Murphey, Todd D.},
  booktitle={Advances in Neural Information Processing Systems 33},
  year={2020}
}
```

# Troubleshooting
If you face any issues with our code or are unable to reproduce our results, please submit a Github issue and we will do our best to address it promptly.
