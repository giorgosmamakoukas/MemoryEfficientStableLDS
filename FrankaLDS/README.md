# Learning and control of the Franka robot using stable LDS

1. The directory `controlExperiments` contains: 
* `Franka_Fig8_exp.mat`, which contains 3 trials of experimentally tracking a figure 8 pattern. The three trials use LQR control developed using a stable LDS model obtained with the SOC algorithm. 

2. The directory `learningLDS` contains the files used to learn stable LDS systems using the experimental Franka data. 
To do this, simply run the `mainExecution` file, which will generate results in the subdirectory `results/`. 

3. The directory `simulationControl` contains the files used to:
- generate LQR control for stable LDS models of the Franka robot obtained using the SOC, CG, and WLS algorithms; 
- perform a Monte Carlo test on tracking a figure 8 pattern (in simulation, using `pybullet`) with the Franka robot. 
To do this, first run `generateLQRgains`, which creates the file `LQR_gains`. Then, run `MonteCarlo_Franka` in a Jupyter notebook and run through the cells. The notebook is set up so that it creates 50 files, each with the tracking results associated with the least-squares method, and the SOC, CG, and WLS algorithms. 
