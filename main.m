clc;
clear;
close all;
warning off;

%% ================= 1. Parameter Settings =================
SearchAgents_no = 30;    % Population size
dim = 50;                % Dimension
Max_iteration = 1000;    % Maximum number of iterations
lb = -100;               % Lower bound
ub = 100;                % Upper bound
run_times = 30;          % Number of independent runs
fun_no_range = 1:28;     % CEC2013 test function range

% Load test functions
fhd = str2func('cec17_func'); 

%% ================= 2. Algorithm Setup =================
Algo_Names = {'DRGO'};
Algo_Funcs = {@DRGO};

%% ================= 3. Excel Storage Container =================
% Table: Statistical Results (Min, Std, Avg, Median, Worst)
Total_Rows = length(fun_no_range) * 5 + 1;
Result_Cell = cell(Total_Rows, 3);
Result_Cell(1, :) = {'Function', 'Metric', 'DRGO'};

%% ================= 4. Main Evaluation Loop =================
func_idx = 0; 
for fun_no = fun_no_range
    func_idx = func_idx + 1;
    func_name = ['F', num2str(fun_no)];
    
    fprintf('\n======================================================\n');
    fprintf('Running Function: %s (Dim=%d) ...\n', func_name, dim);
    
    All_Best_Scores = zeros(run_times, 1); 
    
    % --- 4.1 Independent Runs ---
    for r = 1:run_times
        fprintf('  Run %d/%d: ', r, run_times);
        
        % Fix random seed for reproducibility
        current_seed = sum(100 * fun_no + r);
        rng(current_seed, 'twister');
        
        try
            % Execute DRGO algorithm (ignore convergence curve to save memory)
            [best_score, ~, ~] = Algo_Funcs{1}(SearchAgents_no, Max_iteration, lb, ub, dim, fhd, fun_no);
            
            % Record the best score
            All_Best_Scores(r, 1) = best_score;
        catch ME
            fprintf('[Error] ');
            All_Best_Scores(r, 1) = NaN;
        end
        fprintf('Done.\n');
    end
    
    % --- 4.2 Statistics Calculation and Data Padding ---
    row_start = (func_idx - 1) * 5 + 2;
    Result_Cell(row_start:row_start+4, 1) = repmat({func_name}, 5, 1);
    Result_Cell(row_start:row_start+4, 2) = {'Min'; 'Std'; 'Avg'; 'Median'; 'Worst'};
    
    valid_res = All_Best_Scores(~isnan(All_Best_Scores)); 
    
    % Calculate the 5 evaluation metrics
    if isempty(valid_res)
        stats = [NaN; NaN; NaN; NaN; NaN];
    else
        stats = [min(valid_res); std(valid_res); mean(valid_res); median(valid_res); max(valid_res)];
    end
    Result_Cell(row_start:row_start+4, 3) = num2cell(stats);
    
    fprintf('  %-8s: Avg = %10.2e\n', Algo_Names{1}, stats(3));
end

%% ================= 5. Save Data =================
fprintf('\nSaving data to Excel ...\n');
try
    writecell(Result_Cell, 'DRGO_Result_Metric.xlsx');
    fprintf('  [¡Ì] Data saved successfully to DRGO_Result_Metric.xlsx!\n');
catch
    fprintf('  [x] Save failed. Please ensure the Excel file is not open.\n');
end
fprintf('All runs completed!\n');