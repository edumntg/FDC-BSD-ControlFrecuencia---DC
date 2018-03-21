%   Flujo de carga con barra slack distribuida
%   Con acciones primarias y secundarias del AGC
clc, clear, close all;

Vb = 115;       %kv
Sb = 100;       %mva
fb = 60;        %hz

% [BUSDATA, LINEDATA, GENDATA] = LoadData('BUSDATA_3barras.dat', 'RAMAS_3barras.dat', 'GENDATA_3barras.dat');
% [BUSDATA, LINEDATA, GENDATA] = LoadData('BUSDATA_3barras_3gen.dat', 'RAMAS_3barras.dat', 'GENDATA_3barras_3gen.dat');
[BUSDATA, LINEDATA, GENDATA] = LoadData('DATOS_3b_3g.xlsx', 'BUS', 'RAMAS', 'GEN');

% [BUSDATA, LINEDATA, GENDATA] = LoadData('BUSDATA_Wollenberg.dat', 'RAMAS_Wollenberg.dat', 'GENDATA_Wollenberg.dat');

n = size(BUSDATA, 1);           % el numero de filas en el archivo es igual al numero de barras
nl = size(LINEDATA, 1);         % el numero de filas en el archivo es igual al numero de ramas
ng = size(GENDATA, 1);          % el numero de filas en el archivo es igual al numero de generadores

%%   Aqui se cargaran todos los datos

bustype = BUSDATA(:, 2);
V = BUSDATA(:, 4);
theta = BUSDATA(:, 5);
Pload = BUSDATA(:, 6);

Pconsigna = BUSDATA(:, 8);

R = BUSDATA(:, 10);
FaP = BUSDATA(:, 11);
Betaload = BUSDATA(:, 12);

R(R >= 1e10) = Inf;

ci = GENDATA(:, 2);
bi = GENDATA(:, 3);
ai = GENDATA(:, 4);
Pmin = GENDATA(:, 5);
Pmax = GENDATA(:, 6);

if sum(Pconsigna) - sum(Pload) ~= 0
    disp('La generacion no es igual a la demanda. Corregir datos.');
    break
end

if sum(FaP) ~= 1
    disp('Los factores de participacion para la accion secundaria no suman 1.')
    break
end

% Se calculan todos los Beta
Betagen = 1./R;

%%  Formacion de la Ybus para el FDC
[Ybus2, G, B, g, b] = CreateYbus(LINEDATA, n, nl);

%%  Ejecucion del FDC base
[theta0, Pgen0, Pneta0, Pflow0, Pflow_bus0, ...
Ploss0, Pload0] = FDC_DC(bustype, theta, Pload, Pconsigna, LINEDATA, B, n, nl);

disp('                           ---------- FLUJO DE CARGA BASE ----------                   ');
PrintFDC(theta0, Pgen0, Pload0, Ploss0, Pneta0, n);


%% Control de frecuencia
fprintf('\n');
tipo = input('Ingrese tipo de perturbacion (1 = cambio en carga, 2 = cambio en generacion, 3 = salida de linea): ');
if tipo == 1 || tipo == 2
    barra = input('Ingrese la barra donde ocurre la perturbacion: ');
    deltaPin = input('Ingrese el cambio en potencia (en p.u): ');
    
    deltaPgen = 0;
    deltaPload = 0;
    
    BUSDATA2 = BUSDATA;
    if tipo == 1
        deltaPload = deltaPin;
        deltaP = deltaPload;
        BUSDATA2(barra, 6) = BUSDATA2(barra, 6) + deltaPload;
    else
        deltaPgen = deltaPin;
        deltaP = -deltaPgen;
        BUSDATA2(barra, 8) = BUSDATA2(barra, 8) + deltaPgen;
    end
    
    Beq = 0;
    for i = 1:n
        Beq = Beq + Betagen(i) + Betaload(i);
    end
    
    %%  Accion Primaria
    [thetaprim, Pgenprim, Pnetaprim, Pflowprim, Pflow_busprim, ...
    Plossprim, Ploadprim, deltaf] = FDC_AccionPrimaria(BUSDATA2, LINEDATA, Betagen, Betaload, B, n, nl);

    deltaPmec_primaria = -deltaf.*Betagen;
    
    %%  Luego de la accion primaria, viene la accion secundaria
%{
    %   Para esto, los generadores necesitan un factor de participacion
    %   especificado
    %   Estos se pueden especificar, pero realmente provienen de un
    %   despacho economico
    % 
    %   Aqui, se hara ese despacho
    
%     bi = bi.*Sb; % $/Mwpu-h = $/h
%     ai = ai.*Sb^2; % $/Mwpu^2-h = $/h
    
    %% Solo se toman en cuenta los generadores que participan en control de frecuencia
    
    ng_part = 0;
    
    for i = 1:ng
        if GENDATA(i, 9) == 1
            ng_part = ng_part + 1;
            bi_part(ng_part, 1) = bi(i);
            ai_part(ng_part, 1) = ai(i);
            ci_part(ng_part, 1) = ci(i);
            Pmin_part(ng_part, 1) = Pmin(i);
            Pmax_part(ng_part, 1) = Pmax(i);
        end
    end
    
    [Pgen_ed, lambda_ed, fval_ed, exitflag_ed] = DespachoEconomico(ci_part, bi_part, ai_part, deltaPsys, Pmin_part, Pmax_part, ng_part);
    exitflag_ed
    if exitflag_ed < 0 % unsuccesful solution 
        pause;
    end
    
    % Ahora se calculan los factores de participacion
    FaP = Pgen_ed./(abs(sum(Pload)) + deltaPsys)
    
    for i = 1:ng_part
        BUSDATA2(i, 13) = FaP(i);
    end
%}
    %%  Accion secundaria
    [thetasec, Pgensec, Pnetasec, Pflowsec, Pflow_bussec, ...
    Plosssec, Ploadsec] = FDC_AccionSecundaria(BUSDATA2, LINEDATA, B, n, nl);
    
    deltaPtot = deltaP + Plosssec;
    deltaPmec_secundaria = FaP.*deltaPtot;
else
    
    deltaP = 0;
    barrai = input('Ingrese la barra de partida de la linea: ');
    barraj = input('Ingrese la barra de llegada de la linea: ');
    for i = 1:nl
        if LINEDATA(i,  1) == barrai && LINEDATA(i, 2) == barraj 
            linevec = LINEDATA(i, 1:end);
        end
    end
    
    LINEDATA2 = [];
    k = 1;
    for i = 1:nl
        if LINEDATA(i, 1) == barrai && LINEDATA(i, 2) == barraj
            % Nada
        else
            LINEDATA2(k, 1:size(LINEDATA, 2)) = LINEDATA(i, 1:end);
            k = k + 1;
        end
    end
    nln = size(LINEDATA2, 1);
    [Ybusn, Gn, Bn, gn, bn] = CreateYbus(LINEDATA2, n, nln);
    
    [thetaprim, Pgenprim, Pnetaprim, Pflowprim, Pflow_busprim, ...
    Plossprim, Ploadprim, deltaf] = FDC_AccionPrimaria(BUSDATA, LINEDATA2, Betagen, Betaload, B, n, nln);

    deltaPmec_primaria = -deltaf.*Betagen;

    %%  Accion secundaria
    [thetasec, Pgensec, Pnetasec, Pflowsec, Pflow_bussec, ...
    Plosssec, Ploadsec] = FDC_AccionSecundaria(BUSDATA, LINEDATA2, B, n, nln);
    
    deltaPtot = deltaP + Plosssec;
    deltaPmec_secundaria = FaP.*deltaPtot;

end
disp('                           ---------- ACCION PRIMARIA ----------                   ');
PrintFDC(thetaprim, Pgenprim, Ploadprim, Plossprim, Pnetaprim, n);
fprintf('\n\n');
disp('                            ---------- ACCION SECUNDARIA----------                   ');
PrintFDC(thetasec, Pgensec, Ploadsec, Plosssec, Pnetasec, n);

deltaPcarga = deltaP;
deltaPprim = sum(Ploadprim) - sum(Pconsigna) + Plossprim
deltaf
deltaf_Hz = deltaf*60
fnueva_pu = fb/fb + deltaf;
fnueva_pu
fnueva = fb + deltaf_Hz;
fnueva
deltaPmec_primaria
deltaPmec_secundaria
