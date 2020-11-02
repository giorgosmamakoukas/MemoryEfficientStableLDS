# Introduction

This branch contains the Python implementation of the SOC algorithm appearing in the paper "Memory-Efficient Learning of Stable Linear Dynamical Systems for Prediction and Control" by Giorgos Mamakoukas, Orest Xherija and Todd D. Murphey.

# Requirements
To install the necessary dependencies for this project (assuming you are using the `pip` package manager):

```
pip install -r requirements.txt
```

# Usage

## Basic 
To learn state and control matrices from data `X`, outputs `Y` and  controls `U` we run the command:

```
python train.py \
    --X /path/to/X.npy \
    --Y /path/to/Y.npy \
    --U /path/to/U.npy \ 
    --save_dir results/ \
    --seed 2020 \
    --log_memory \
    --store_matrix 
```
This will produce the following output in directory `results/`
- a `.json` file `sample_results.json` containing the execution time, memory usage, least-squares maximum absolute eigenvalue and relative error
- a `.npy` file `sample_amatrix.json` containing the state matrix `A`
- a `.npy` file `sample_bmatrix.json` containing the state matrix `B`

Note that the `--U` command-line argument is optional. If you do not procide it, the algorithm will learn a linear dynamical system without inputs and will consequently not output matrix `sample_bmatrix.npy`.

## Advanced configuration options
We have included a number of more advanced configuration options that you can provide in order to have more control over the learning process. They are briefly summarized below:

- `--sample_id`: identifying name for output files; defaults to `sample`
- `--eps`: numerical precision threshold; defaults to `1e-12`
- `--stability_relaxation`: amount by which to relax stablity threshold; defaults to `0`
- `--time_limit`: time duration (in sec) after which to terminate program; defaults to `1800`
- `--step_size_factor`: factor by which to reduce step size in fast-gradient method; defaults to `5`
- `--fgm_max_iter`: maximum number of times to apply fast-gradient method; defaults to `20`
- `--alpha`: fast-gradient method tuning parameter; defaults to `0.5`
- `--conjugate_gradient`: whether to use conjugate gradient method; `False` if argumnt is absent
- `--log_memory`: whether to record memory required by objects; `False` if argumnt is absent
- `--store_matrix`: whether to store state and control matrices to disk; `False` if argument is absent
- `--seed`: random seed for reproducibility
