%% Eduardo Montilva 12-10089
% Script el cual tiene como funcion armar imprimir los resultados del flujo
% de carga
function PrintFDC(theta, Pgen, Pload, Ploss, Pneta, n)
	V = ones(n, 1);
    Qgen = zeros(n, 1);
    Qload = zeros(n, 1);
    Qloss = 0;
    Qneta = zeros(n, 1);
    Sshunt = zeros(n, 1);
    head = ['    Bus  Voltage  Angle    ------Load------    ---Generation---    ---P y Q Netos---   Injected'
            '    No.  Mag.      Rad      (p.u)   (p.u)       (p.u)    (p.u)       (p.u)    (p.u)     (p.u)  '
            '                                                                                               '];

    disp(head)

    for i = 1:n
         fprintf(' %5g', i), fprintf(' %7.4f', V(i)), fprintf(' %8.4f', theta(i)), fprintf(' %9.4f', Pload(i)), fprintf(' %9.4f', Qload(i)), fprintf(' %9.4f', Pgen(i)), fprintf(' %9.4f ', Qgen(i)), fprintf(' %9.4f', Pneta(i)), fprintf(' %9.4f', Qneta(i)), fprintf(' %8.4f\n', -imag(Sshunt(i)))
    end
        fprintf('      \n'), fprintf('    Total              '), fprintf(' %9.4f', sum(Pload)), fprintf(' %9.4f', sum(Qload)), fprintf(' %9.4f', sum(Pgen)), fprintf(' %9.4f', sum(Qgen)), fprintf(' %9.4f', sum(Pneta)), fprintf(' %9.4f', sum(Qneta)), fprintf(' %9.4f\n\n', sum(-imag(Sshunt)))
        fprintf('    Total loss:           '), fprintf(' P: %9.4f ', Ploss), fprintf(' Q: %9.4f', Qloss)
        fprintf('\n');
end