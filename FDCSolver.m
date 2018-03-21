function F = FDCSolver(x, LINEDATA, bustype, theta, Pload, Pconsigna, B, n, nl)
    
    Pik = zeros(n,n);
    Ploss = zeros(n,n);
    Plossbus = zeros(n,1);
    Pflowbus = zeros(n,1);
    
    
    % Se cargan las resistencias
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k % es linea
            Rik(i,k) = LINEDATA(l, 3);
            Rik(k,i) = LINEDATA(l, 3);
        end
    end
    %% Primero vamos a calcular los flujos de potencia para cada barra (Lo que sale/entra por las lineas)
    
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1
            theta(i) = x(v);
            v = v + 1;
        end
        
        v2 = 1;
        for k = 1:n
            if bustype(k) ~= 1
                theta(k) = x(v2);
                v2 = v2 + 1;
            end

            if i ~= k
                Pik(i,k) = B(i,k)*(theta(i) - theta(k));
            end
        end
        Pflowbus(i) = sum(Pik(i,1:size(Pik, 2)));
    end
    %% Ahora, calculamos las perdidas totales en el sistema
    for i = 1:n
        for k = 1:n
            if i ~= k
                Ploss(i,k) = Pik(i,k) + Pik(k,i);
            end
        end
    end

    for i = 1:n
        for k = 1:n
            if k > i
                Plossbus(i) = Plossbus(i) + Ploss(i,k);
            end
        end
    end
    
    Plosstotal = sum(Plossbus);             % Perdidas totales en el sistema
    
    %% A este punto, ya tenemos flujos de lineas, potencia de shunts y perdidas totales, ademas de P/Q de cargas
    % Por tanto ya podemos agregar las ecuaciones de potencia para cada
    % barra
    
    %%  Vamos a definir las variables que utilizaremos en las ecuaciones de flujo de carga
        % Se definen las variables con sus valores asignados, pero si es
        % una variable de estado debera asignarse el valor del vector de
        % salida del FSOLVE
    
        % Las variables vienen definidas en el siguiente orden
        % Si la barra es SLACK/REF
            % P (consigna + k perdidas + k desbalance)
            % Q
        % Si la barra es PV
            % P (consigna + k perdidas + k desbalance)
            % d
            % Q
        % Si la barra es PQ
            % d
            % V
    v = 1;
    for i = 1:n
        Pgi = Pconsigna(i);                 % Potencia activa generada, declarada como consigna
        
        %% Las ecuaciones de P y Q vendran de la siguiente forma
        %  Pgen = Pload + Ki*Ploss_tot - Ki*Punb
        %  Qgen = Qload + Qflow_bus + Qshunt;
        
        %% El orden de las ecuaciones sera
            % P
            % Q

        if bustype(i) ~= 1
            F(v) = Pgi - Pload(i) - Pflowbus(i);
            v = v + 1;
        end
    end
end