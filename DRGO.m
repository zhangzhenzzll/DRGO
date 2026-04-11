function [Best_Score, Best_Pos, Convergence_curve] = DRGO(nPop, maxIter, lb, ub, dim, fhd, fun_no)
% Dynamic Research Group Optimization (DRGO)
% Core Mechanism:
% - PhD ratio is fixed at 10%.
% - Mentor pool shrinks linearly from 40% to 10% to balance exploration and exploitation.

    %% --- 1. Initialization ---
    PhD_Rate = 0.1;                 
    nPhD = round(nPop * PhD_Rate); 
    if nPhD < 2
        nPhD = 2; 
    end
    
    if length(lb) == 1
        lb = repmat(lb, 1, dim);
        ub = repmat(ub, 1, dim);
    end
    
    LB_Mat = repmat(lb, nPop, 1);
    UB_Mat = repmat(ub, nPop, 1);
    
    X = lb + (ub - lb) .* rand(nPop, dim);
    Fitness = zeros(nPop, 1);
    
    for i = 1:nPop
        Fitness(i) = feval(fhd, X(i, :)', fun_no); 
    end
    
    [Fitness, idx] = sort(Fitness);
    X = X(idx, :);
    
    Best_Score = Fitness(1);
    Best_Pos = X(1, :);
    Convergence_curve = zeros(1, maxIter);
    
    %% --- 2. Main Loop ---
    for t = 1:maxIter
        
        w = (1 - (t / maxIter))^2; 
        a = 1 - (t / maxIter);
        
        % Dynamically adjust the mentor pool size (linear decay from 40% to 10%)
        Senior_Rate = 0.4 - 0.3 * (t / maxIter);
        nSenior = round(nPop * Senior_Rate);
        if nSenior < nPhD
            nSenior = nPhD; % Ensure the pool includes at least the PhD students
        end 
        
        X_new = X; 
        
        %% === Stage 1: PhD Students (Dynamic Spiral Approximation) ===
        idx_phd = 2 : nPhD;
        curr_nPhD = length(idx_phd);
        
        if curr_nPhD > 0
            Mentor_Mat = repmat(Best_Pos, curr_nPhD, 1);
            Distance = abs(Mentor_Mat - X(idx_phd, :));
            
            l = (rand(curr_nPhD, 1) * 2 - 1) .* a; 
            l_mat = repmat(l, 1, dim);
            
            X_new(idx_phd, :) = Mentor_Mat + ...
                Distance .* exp(l_mat) .* cos(2 * pi .* l_mat) + ... 
                randn(curr_nPhD, dim) .* w * 0.1; 
        end
        
        %% === Stage 2: Master Students (Learning from Mentors) ===
        idx_master = nPhD + 1 : nPop;
        curr_nMaster = length(idx_master);
        
        if curr_nMaster > 0
            % Tournament selection from the dynamic mentor pool
            cand1 = randi([1, nSenior], curr_nMaster, 1);
            cand2 = randi([1, nSenior], curr_nMaster, 1);
            
            better_mask = cand1 < cand2; 
            final_senior_idx = cand2;
            final_senior_idx(better_mask) = cand1(better_mask);
            
            Senior_Mat = X_new(final_senior_idx, :); 
            
            X_new(idx_master, :) = X(idx_master, :) + ...
                rand(curr_nMaster, dim) .* (Senior_Mat - X(idx_master, :));
        end
        
        %% === Stage 3: Master Students (Hybrid Mutation with Crossover) ===
        if curr_nMaster > 0
            r1 = randi(nPop, curr_nMaster, 1);
            r2 = randi(nPop, curr_nMaster, 1);
            Diff_Vector = X(r1, :) - X(r2, :);
            
            Method_Prob = rand(curr_nMaster, 1);
            Cauchy_Val = tan(pi * (rand(curr_nMaster, dim) - 0.5));
            Gaussian_Val = randn(curr_nMaster, dim);
            
            Step = zeros(curr_nMaster, dim);
            Use_Cauchy = repmat(Method_Prob < 0.5, 1, dim);
            Step(Use_Cauchy) = Cauchy_Val(Use_Cauchy);
            Step(~Use_Cauchy) = Gaussian_Val(~Use_Cauchy);
            
            Scale_Factor = 0.2 + 0.8 * rand(curr_nMaster, 1);
            Scale_Mat = repmat(Scale_Factor, 1, dim);
            
            Final_Mutation = Step .* Diff_Vector .* Scale_Mat;
            
            % Crossover mask (CR = 0.8)
            CR = 0.8; 
            Crossover_Mask = rand(curr_nMaster, dim) < CR;
            
            Temp_X = X_new(idx_master, :);
            Update_Val = Temp_X(Crossover_Mask) + Final_Mutation(Crossover_Mask);
            Temp_X(Crossover_Mask) = Update_Val;
            
            X_new(idx_master, :) = Temp_X;
        end
        
        %% --- 3. Boundary Control and Evaluation ---
        LB_Violated = X_new < LB_Mat;
        X_new(LB_Violated) = LB_Mat(LB_Violated) + rand(sum(LB_Violated(:)), 1) .* (UB_Mat(LB_Violated) - LB_Mat(LB_Violated)) * 0.05;
        
        UB_Violated = X_new > UB_Mat;
        X_new(UB_Violated) = UB_Mat(UB_Violated) - rand(sum(UB_Violated(:)), 1) .* (UB_Mat(UB_Violated) - LB_Mat(UB_Violated)) * 0.05;
        
        X_new = max(X_new, LB_Mat);
        X_new = min(X_new, UB_Mat);
        
        % Greedy selection
        for i = 1:nPop
            new_fit = feval(fhd, X_new(i, :)', fun_no);
            if new_fit < Fitness(i)
                Fitness(i) = new_fit;
                X(i, :) = X_new(i, :);
            end
        end
        
        % Sort and update global best
        [Fitness, sorted_idx] = sort(Fitness);
        X = X(sorted_idx, :);
        
        if Fitness(1) < Best_Score
            Best_Score = Fitness(1);
            Best_Pos = X(1, :);
        end
        
        Convergence_curve(t) = Best_Score;
    end
end