function [Best_Score,Best_Pos,Convergence_curve,info] = DRGO(nPop,maxFEs,lb,ub,dim,fobj)
% Final manuscript implementation. maxFEs includes initialization.
% The three-stage framework is unchanged; the signed spiral displacement is
% used so the doctoral-candidate step retains directional information.
[Best_Score,Best_Pos,Convergence_curve,info] = ...
    DRGO_FE(nPop,maxFEs,lb,ub,dim,fobj,struct('spiral_signed',true));
end
