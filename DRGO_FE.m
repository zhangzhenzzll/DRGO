function [Best_Score,Best_Pos,Convergence_curve,info] = DRGO_FE(nPop,maxFEs,lb,ub,dim,fobj,opts)
% maxFEs INCLUDES initialization. fobj accepts a row vector, returns scalar.
% Set rng(seed,'twister') OUTSIDE. info.feGrid is the curve's x axis.
if nargin<7, opts=struct(); end
o=drgo.options(opts); [lb,ub]=drgo.bounds(lb,ub,dim);
b=drgo.Budget(fobj,nPop,maxFEs,lb,ub,false);
t=tic; diagnostics=drgo.run(b,nPop,dim,lb,ub,o);
info=b.result(); info.seconds=toc(t); info.diagnostics=diagnostics; info.options=o;
Best_Score=info.best; Best_Pos=info.bestPosition; Convergence_curve=info.curve;
end
