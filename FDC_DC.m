%% Eduardo Montilva 12-10089
% Script para la solucion del flujo de carga, mediante fsolve

function [theta, Pgen, Pneta, Pik, Pflowbus, Ploss, Ploada] = FDC_DC(bustype, theta, Pload, Pconsigna, LINEDATA, B, n, nl)

    Pgen = Pconsigna;
    Pik = zeros(n, n);
    Pflowbus = zeros(n, 1);
    Plossbus = zeros(n,n);
    Ploss = 0;
    Ploada = -Pload;

%     Pdesbalance = sum(Pconsigna) - sum(Pload);
    
    v = 1;
    for i = 1:n
        if bustype(i) == 2 % incognitas: theta
            X0(v) = theta(i);
            v = v + 1;
        elseif bustype(i) == 0 %incognitas: theta
            X0(v) = theta(i);
            v = v + 1;
        end
    end

    %% Ejecucion del fsolve (iteraciones)
    options = optimset('Display','off');    
    [x,~,exitflag] = fsolve(@(x)FDCSolver(x, LINEDATA, bustype, theta, Pload, Pconsigna, B, n, nl), X0, options);
    exitflag
    x
    %% Una vez terminadas las iteraciones, se obtienen las variables de salida y se recalculan potencias
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1 % no es barra referencia
            theta(i) = x(v);
            v = v + 1;
        end
    end
    
    %% Calculo de flujos en lineas y perdidas
    for i = 1:n
        for k = 1:n
            if i ~= k
                Pik(i,k) = B(i,k)*(theta(i) - theta(k));
            end
        end
        Pflowbus(i) = sum(Pik(i, 1:end));
    end

    %% Calculo de las perdidas
    
    for i = 1:n
        for k = 1:n
            if i ~= k
                Plossbus(i,k) = Pik(i,k) + Pik(k,i);
                if k > i
                    Ploss = Ploss + Plossbus(i,k);
                end
            end
        end
    end

    Pneta = Pgen - Pload;

%     Pdesbalance = Pdesbalance + Ploss;

    %% VARIABLES PARA GARANTIZAR EL BUEN FUNCIONAMIENTO DEL PROGRAMA
    % La P de salida en cada barra debe ser igual a la P neta de la misma
    fprintf('Diferencia entre Pneta y Psalida para cada barra: %s\n', mat2str(Pgen - Pload - Pflowbus));
%     fprintf('Diferencia entre Qneta y Qsalida para cada barra: %s\n', mat2str(Qgen - imag(Sshunt) - abs(Qload) - Qflow_bus));
%     Pdesbalance_result = sum(Pgen) - abs(sum(Pload));
%     fprintf('Desbalance inicial en el sistema: %s\n', num2str(Pdesbalance));
%     fprintf('Desbalance final en el sistema: %s\n\n', num2str(Pdesbalance_result));
end