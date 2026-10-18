version
ver
fprintf('MATLABROOT=%s\n',matlabroot);
which fmincon -all
which fit -all
which ga -all
for f = ["Optimization_Toolbox","Curve_Fitting_Toolbox","GADS_Toolbox"]
 fprintf('LICENSE %s = %d\n',f,license('test',char(f)));
end
try; [u,s]=memory; disp(u); disp(s); catch; end
