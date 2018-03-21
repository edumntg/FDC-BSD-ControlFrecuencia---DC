% Despaco Economico

function [Pgen, lambda, fval, exitflag] = DespachoEconomico(ci, bi, ai, deltaPsys, Pmin, Pmax, ng)

    %% Matriz Aeq sera siempre una matriz ng+1 * ng+1

    Aeq = zeros(ng+1,ng+1);
    for i = 1:ng
%         Aeq(i,i) = 2*ai(i)*fuel(i);
        Aeq(i,i) = 2*ai(i);
    end

    for i = 1:ng
        Aeq(ng+1, i) = 1;
        Aeq(i, ng+1) = -1;
    end

%     beq = -bi.*fuel;
    beq = -bi;
%     beq(ng+1) = Pload;
    beq(ng+1) = deltaPsys;

    lb = Pmin;
%     lb = Pmin.*0 - 1.*abs(deltaPsys);
%     lb = -abs(deltaPsys);
    lb(ng+1) = -Inf;
    ub = Pmax;
%     ub = abs(deltaPsys);
%     ub = Pmax.*0 + 1.*abs(deltaPsys);
    ub(ng+1) = Inf;

    A = [];
    b = [];
    lb
    ub
    pause
    x0 = zeros(ng+1, 1);
    options = optimset('display', 'on', 'algorithm', 'interior-point'); 
    [x,fval,exitflag] = fmincon('DespachoEconomico_FuncObjetivo', x0, A, b, Aeq, beq, lb, ub, [], options, ci, bi, ai, ng);

    Pgen = x(1:ng);
    lambda = x(ng+1);
    
    % fitnessfcn = @DespachoEconomico_FuncObjetivo_GA;
    % nvars = size(lb, 1);
    % iter = 1:300;
    % costo = zeros(length(iter), 1);
    % Pgen = zeros(length(iter), 1);
    % 
    % gaoptions = gaoptimset('TolCon', 1e-8);
    % for i = iter
    %     xga = ga(fitnessfcn, nvars, A, b, Aeq, beq, lb, ub, [], gaoptions);
    %     costo(i) = xga(ng+1);
    %     Pgen(i) = sum(xga(1:ng));
    %     i
    % end
    % 
    % figure(1), plot(iter, costo);
    % figure(2), plot(iter, Pgen);
    % 
    % maxcosto = max(costo);
    % optimo = 0;
    % for i = iter
    %     if abs(Pgen(i) - Pload) <= 1e-6 && costo(i) < maxcosto
    %         optimo = i;
    %     end
    % end
end