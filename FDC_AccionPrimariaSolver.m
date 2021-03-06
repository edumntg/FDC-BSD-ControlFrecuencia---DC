function F = FDC_AccionPrimariaSolver(x, LINEDATA, bustype, Betagen, Betaload, theta, Ploadsp, Pconsigna, B, n, nl)
    
    Pik = zeros(n, n);
    Pflowbus = zeros(n, 1);
    Plossline = zeros(n, 1);
    
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k
            Rik(i,k) = LINEDATA(l, 3);
            Rik(k,i) = LINEDATA(l, 3);
        end
    end
    
    %% Se establecen las variables
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1
            theta(i) = x(v);
            v = v + 1;
        end
    end
    deltaf = x(end);
    
    %% Primero vamos a calcular los flujos de potencia para cada barra (Lo que sale/entra por las lineas)

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

    %% Ahora, calculamos las perdidas totales en el sistema

    % Las perdidas son para cada linea. Asi:
    for l = 1:nl
        i = LINEDATA(l, 1);
        k = LINEDATA(l, 2);
        if i ~= k % es una linea
            Plossline(l) = Rik(i,k)*Pik(i,k)^2;
        end
    end
    
    Plosstotal = sum(Plossline);
    
    Ploadnew = Ploadsp + deltaf.*Betaload;
    deltaP = sum(Ploadsp) - sum(Pconsigna) + Plosstotal;
    deltaPg = -deltaf.*Betagen;
    Pgen = Pconsigna + deltaPg;
    Beq = sum(Betagen) + sum(Betaload);
    
    v = 1;
    for i = 1:n
        if bustype(i) ~= 1
            F(v) = Pgen(i) - Ploadnew(i) - Pflowbus(i);
            v = v + 1;
        end
    end
    
    F(end+1) = deltaf + deltaP/Beq;
end