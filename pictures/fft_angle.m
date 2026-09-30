
scatter(1:64,asind((0:63)*2/64-1),"filled")
ylim([-90 90])
xlim([1 64])
xticks(0:8:64)
ylabel("Kąt [°]")
xlabel("Przedział FFT")