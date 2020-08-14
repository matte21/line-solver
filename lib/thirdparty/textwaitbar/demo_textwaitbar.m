Msg = 'In progress';
Niter = 1000;

for i = 1:Niter
    textwaitbar(i, Niter, Msg);
    pause(0.005);
end