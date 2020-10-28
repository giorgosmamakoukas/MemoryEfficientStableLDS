parallel --bar "python train.py \
    --data {1} \
    --save_dir out_results/ \
    --subspace_dim {2} \
    --log_memory \
    --seed 2000" ::: \
    seqs/*.npy ::: \
    10 15