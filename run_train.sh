parallel --bar "python train.py \
    --data {1} \
    --subspace_dim {2} \
    --log_memory 1 \
    --seed 2000" ::: \
    test/*.npy ::: \
    10 15