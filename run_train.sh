parallel --bar "python train_prediction.py \
    --data {1} \
    --save_dir out_results/ \
    --subspace_dim {2} \
    --time_limit 1800 \
    --log_memory \
    --seed 2000" ::: \
    seqs/seq_0.npy ::: \
    10