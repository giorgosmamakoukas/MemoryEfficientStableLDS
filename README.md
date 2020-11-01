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
To get the datasets, read the instructions in the `data` directory. The data for the Franka Emika Panda experiments is contained in the `FrankaLDS` directory. 

## Data Preparation

To prepare the datasets for the UCLA, UCSD and DynTex benchmarks, follow the instructions in the `prepare_data` directory.

## Dynamical Texture Experiments

To reproduce our results for the UCLA, UCSD and DynTex benchmarks, you will need to run the `ReconstructImage.m` file. **NOTE**: you will need to set the configuration options at the top of the file so that it can work on your particular system.

## Franka Emika Panda Experiments

For our results of Franka Emika Panda, consult the `FrankaLDS` directory.

# Citing

If you find this project useful, consider

- Starring this repository ⭐
- Watching this repository for updates 
- Citing our paper

```
@inproceedings{mamakoukas2020_memEfficientLDS,
  title={Memory-Efficient Learning of Stable Linear Dynamical Systems for Prediction and Control},
  author={Mamakoukas, Giorgos and Xherija, Orest and Murphey, Todd D.},
  booktitle={Advances in Neural Information Processing Systems 33},
  year={2020}
}
```

# Troubleshooting
If you face any issues with our code or are unable to reproduce our results, please submit a Github isue and we will do our best to address it promptly.
