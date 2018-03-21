%% Eduardo Montilva 12-10089
% Script para la solucion del flujo de carga, mediante fsolve
%       Para ejecutar este script, se debe eecutar un flujo de carga base
%       Con estos valores bases obtenidos, se pueden modelar las cargas
%       como potencia,impedancia o corriente ctte

function [theta, Pgen, Pneta, Pik, Pflowbus, Ploss, Pload] = FDC_AccionSecundaria(BUSDATA, LINEDATA, B, n, nl)

    Pik = zeros(n, n);
    Pflowbus = zeros(n, 1);
    Plossline = zeros(n, 1);
    
    bustype = BUSDATA(:, 2);
    theta = BUSDATA(:, 5);
    Pload = BUSDATA(:, 6);
    Pconsigna = BUSDATA(:, 8);
    FaP = BUSDATA(:, 11);

    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k
            Rik(i,k) = LINEDATA(l, 3);
            Rik(k,i) = LINEDATA(l, 3);
        end
    end
    
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1 % incognitas: Q y delta
            X0(v) = theta(i);
            v = v + 1;
        end
    end

    %% Ejecucion del fsolve (iteraciones)
    options = optimset('Display','off');
    
    [x,~,exitflag] = fsolve(@(x)FDC_AccionSecundariaSolver(x, LINEDATA, bustype, FaP, theta, Pload, Pconsigna, B, n, nl), X0, options);
    exitflag
    x
    %% Una vez terminadas las iteraciones, se obtienen las variables de salida y se recalculan potencias
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1 % incognitas: delta(si no es ref ang) y Q
            theta(i) = x(v);
            v = v + 1;
        end
    end

    %% Calculo de flujos en lineas
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k % es linea
            Pik(i,k) = B(i,k)*(theta(i) - theta(k));
            Pik(k,i) = B(k,i)*(theta(k) - theta(i));
        end
    end
    
    for i = 1:n
        Pflowbus(i) = sum(Pik(i, 1:end));
    end

    %% Calculo de las perdidas
    % Estas vienen asociada a cada linea, Asi
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k % es linea
            Plossline(l) = Rik(i,k)*Pik(i,k)^2;
        end
    end

    Ploss = sum(Plossline);
    
    deltaPtot = sum(Pload) - sum(Pconsigna) + Ploss;
    deltaPg = FaP.*deltaPtot;
    Pgen = Pconsigna + deltaPg;
    Pneta = Pgen - Pload;
   
%     Pdesbalance = sum(Pconsig) - sum(Pload);
%     Pdesbalance_result = sum(Pgen) - abs(Ploada);
    %% VARIABLES PARA GARANTIZAR EL BUEN FUNCIONAMIENTO DEL PROGRAMA
    % La P de salida en cada barra debe ser igual a la P neta de la misma
    fprintf('Diferencia entre Pneta y Psalida para cada barra: %s\n', mat2str(Pgen - Pload - Pflowbus));
%     fprintf('Diferencia entre Qneta y Qsalida para cada barra: %s\n', mat2str(Qgen - imag(Sshunt) - abs(Qloada) - Qflow_bus));
% 
%     fprintf('Desbalance inicial en el sistema: %s\n', num2str(Pdesbalance));
%     fprintf('Desbalance final en el sistema: %s\n\n', num2str(Pdesbalance_result));
end