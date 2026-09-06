% assumes data loaded using analyze.mlx

cub = fft(cube,[],1);

subplot(2,1,1)
plot(rngGrid,squeeze(sum(sum(abs(t(rngIdxs,:,:)),3),2)))