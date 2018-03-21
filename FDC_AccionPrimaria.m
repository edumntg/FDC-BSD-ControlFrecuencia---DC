%% Eduardo Montilva 12-10089
% Script para la solucion del flujo de carga, mediante fsolve
%       Para ejecutar este script, se debe eecutar un flujo de carga base
%       Con estos valores bases obtenidos, se pueden modelar las cargas
%       como potencia,impedancia o corriente ctte

function [th, Pgen, Pneta, Pik, Pflowbus, Ploss, Ploadnew, deltaf] = FDC_AccionPrimaria(BUSDATA, LINEDATA, Betagen, Betaload, B, n, nl)


    Pik = zeros(n, n);
    Pflowbus = zeros(n, 1);

    Plossline = zeros(n, 1);
    
    bustype = BUSDATA(:, 2);
    theta = BUSDATA(:, 5);
    Pload = BUSDATA(:, 6);
    Pconsigna = BUSDATA(:, 8);
    
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k
            Rik(i,k) = LINEDATA(l, 3);
            Rik(k,i) = LINEDATA(l, 3);
        end
    end
    
    th = theta;
    
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1 % incognitas: Q y delta
            X0(v) = th(i);
            v = v + 1;
        end
    end
    X0(end+1) = 0;

    %% Ejecucion del fsolve (iteraciones)
    options = optimset('Display','off');
    
    [x,~,exitflag] = fsolve(@(x)FDC_AccionPrimariaSolver(x, LINEDATA, bustype, Betagen, Betaload, th, Pload, Pconsigna, B, n, nl), X0, options);
    exitflag
    x
    %% Una vez terminadas las iteraciones, se obtienen las variables de salida y se recalculan potencias
    
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1 % incognitas: delta(si no es ref ang) y Q
            th(i) = x(v);
            v = v + 1;
        end
    end
    deltaf = x(end);
    
    %% Calculo de flujos en lineas
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k % es linea
            Pik(i,k) = B(i,k)*(th(i) - th(k));
            Pik(k,i) = B(k,i)*(th(k) - th(i));
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
    %% Calculo del deltaf que toma cada generador
    deltaPg = -deltaf.*Betagen;
    
    Pgen = Pconsigna + deltaPg;
    Ploadnew = Pload + deltaf.*Betaload;
    Pneta = Pgen - Ploadnew;

%     Pdesbalance = sum(Pconsig) - sum(Pload);
%     Pdesbalance_result = sum(Pgen) - abs(Ploada);
    %% VARIABLES PARA GARANTIZAR EL BUEN FUNCIONAMIENTO DEL PROGRAMA
    % La P de salida en cada barra debe ser igual a la P neta de la misma
    fprintf('Diferencia entre Pneta y Psalida para cada barra: %s\n', mat2str(Pgen - Ploadnew - Pflowbus));
%     fprintf('Diferencia entre Qneta y Qsalida para cada barra: %s\n', mat2str(Qgen - imag(Sshunt) - abs(Qloada) - Qflow_bus));
% 
%     fprintf('Desbalance inicial en el sistema: %s\n', num2str(Pdesbalance));
%     fprintf('Desbalance final en el sistema: %s\n\n', num2str(Pdesbalance_result));
end