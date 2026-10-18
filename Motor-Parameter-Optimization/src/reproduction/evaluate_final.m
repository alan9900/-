function evaluate_final(scenario)
assert(any(strcmp(scenario,{'baseline','param'})), 'Only baseline and parameter optimization are supported.');
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); out=fullfile(root,'runtime');
set(groot,'defaultFigureVisible','off');
timer_eval=tic;
run(fullfile(root,'src','reproduction','eval_final_body.m'));
angles_full=angles; torque_quarter_full=T;
ix=ismember(angles,0:29); angles_deg=angles(ix)'; torque_full_Nm=4*T(ix)';
assert(numel(torque_full_Nm)==30 && all(isfinite(torque_full_Nm)));
magnet_area_m2=sum([Rotor.Geometry(patchesRotor.Magnets).Area]);
mean_torque_Nm=mean(torque_full_Nm); torque_std_Nm=std(torque_full_Nm,1);
meta=local_meta; source_file=fullfile(out,'data',scenario,'final_rotor.txt');
cnames=vertcat(meta.constraints.Name); itorque=find(cnames=="TorqueMEAN");
torque_target_Nm=4*meta.constraints(itorque).Value;
cgeo=GEO_IPMrotor_V_1_constr(meta.opts_final);
physical_x=vertcat(meta.parameters.Value); lower=vertcat(meta.parameters.Min); upper=vertcat(meta.parameters.Max);
normalized_bound_violation=max([0;(lower-physical_x)./(upper-lower);(physical_x-upper)./(upper-lower)]);
constraint_max_violation=max([0,cgeo(:)',(torque_target_Nm-mean_torque_Nm)/4*meta.constraints(itorque).Scaling,normalized_bound_violation]);
history=load(fullfile(out,'data',[scenario '_opt.mat']));
hr=history.OptimizationHistory(end).Responses; hn=vertcat(hr.Name);
check=struct('scenario',scenario,'provenance','local_run','optimizer_mean_full_Nm',4*hr(hn=="TorqueMEAN").Value,'reevaluated_mean_full_Nm',mean_torque_Nm,'optimizer_std_full_Nm',4*hr(hn=="TorqueSTD").Value,'reevaluated_std_full_Nm',torque_std_Nm,'optimizer_area_quarter_m2',hr(hn=="Cost").Value,'reevaluated_area_quarter_m2',magnet_area_m2);
writetable(struct2table(check),fullfile(out,'data',[scenario '_reevaluation_check.csv']));
provenance='local_run'; elapsed_s=meta.elapsed_s; evaluation_elapsed_s=toc(timer_eval);
solver_output=meta.solver_status.solver_output; exitflag=meta.solver_status.exitflag;
iterations=solver_output.iterations; func_count=solver_output.funcCount;
status='partial'; if exitflag>0 && constraint_max_violation<=1e-6; status='reproduced'; end
commit='e61673e10d4a7f164b713fb744e19bb69973f7e9'; matlab_version=version; timestamp=string(datetime('now','TimeZone','Asia/Shanghai'));
summary=struct('scenario',scenario,'status',status,'provenance',provenance,'commit',commit,'matlab_version',matlab_version,'timestamp',timestamp,'elapsed_s',elapsed_s,'evaluation_elapsed_s',evaluation_elapsed_s,'iterations',iterations,'func_count',func_count,'exitflag',exitflag,'mean_torque_Nm',mean_torque_Nm,'torque_std_Nm',torque_std_Nm,'magnet_area_m2',magnet_area_m2,'torque_target_Nm',torque_target_Nm,'constraint_max_violation',constraint_max_violation,'normalized_bound_violation',normalized_bound_violation,'objective_final',meta.solver_status.objective_final,'max_field_residual_squared',max(residual_squared),'source_file',source_file);
save(fullfile(out,'data',[scenario '_evaluation.mat']),'summary','angles_deg','torque_full_Nm','angles_full','torque_quarter_full','magnet_area_m2','cgeo');
writetable(struct2table(summary),fullfile(out,'data',[scenario '_metrics.csv']));
writetable(table(angles_deg,torque_full_Nm,repmat("local_run",30,1),'VariableNames',{'angles_deg','torque_full_Nm','provenance'}),fullfile(out,'data',[scenario '_torque.csv']));
fid=fopen(fullfile(out,'data',[scenario '_summary.json']),'w','n','UTF-8'); fprintf(fid,'%s',jsonencode(summary,PrettyPrint=true)); fclose(fid);
fid=fopen(fullfile(out,'data',scenario,'final_metadata.json'),'w','n','UTF-8'); fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true)); fclose(fid);
fprintf('REEVALUATION_SUCCESS %s mean_full=%.12g std_full=%.12g area_quarter=%.12g violation=%.12g exitflag=%d\n',scenario,mean_torque_Nm,torque_std_Nm,magnet_area_m2,constraint_max_violation,exitflag);
end
