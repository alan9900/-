function package_parameter_results()
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=fullfile(root,'runtime'); out=fullfile(old,'parameter_optimization');
for d=["figures","data","logs"]; if ~isfolder(fullfile(out,d)); mkdir(fullfile(out,d)); end; end
B=load(fullfile(old,'data','baseline.mat')); E=load(fullfile(old,'data','param_evaluation.mat')); D=load(fullfile(old,'data','param_opt.mat')); meta=load(fullfile(old,'data','param','final_metadata.mat'));
assert(isequal(B.angles_deg(:),E.angles_deg(:)),'Angle samples differ');
P=meta.parameters; H=D.OptimizationHistory; summary=E.summary;
initial_model_parameters=geometry_defaults('GEO_IPMrotor_V_1');
sd=geometry_defaults('GEO_DISstator_2'); ff=fieldnames(sd); for k=1:numel(ff); initial_model_parameters.(ff{k})=sd.(ff{k}); end
ff=fieldnames(B.opts); for k=1:numel(ff); initial_model_parameters.(ff{k})=B.opts.(ff{k}); end
initial_model_parameters.Phase0=0;
initial_model_parameters.HEIGHT=0.035; initial_model_parameters.axial_length_m=0.035; initial_model_parameters.current_amplitude_A=3; initial_model_parameters.number_turns=35; initial_model_parameters.pole_pairs=2;
initial_model_parameters.GAP=(initial_model_parameters.SD2-initial_model_parameters.RD1)/2;
copyfile(fullfile(old,'data','baseline.mat'),fullfile(out,'data','baseline.mat'));
copyfile(fullfile(old,'data','param_opt.mat'),fullfile(out,'data','param_opt.mat'));
copyfile(fullfile(old,'data','param_evaluation.mat'),fullfile(out,'data','param_evaluation.mat'));
copyfile(fullfile(old,'data','param_evaluation_raw.mat'),fullfile(out,'data','param_evaluation_raw.mat'));
copyfile(fullfile(old,'data','param_summary.json'),fullfile(out,'data','param_summary.json'));
copyfile(fullfile(old,'data','param_reevaluation_check.csv'),fullfile(out,'data','param_reevaluation_check.csv'));
copyfile(fullfile(old,'data','param'),fullfile(out,'data','final_design'));
for name=["baseline_rotor.txt","baseline_stator.txt"]; copyfile(fullfile(old,'data',name),fullfile(out,'data',name)); end
for name=["environment.log","baseline.log","param_opt.log","param_reevaluation.log","wrapper_checks.log"]
 if isfile(fullfile(old,'logs',name)); copyfile(fullfile(old,'logs',name),fullfile(out,'logs',name)); end
end
for name=["commit.txt","ENVIRONMENT.md","SCRIPT_MAP.md","execution_changes.patch","author_archive_integrity.json","author_archive_sha256.json"]
 if isfile(fullfile(old,name)); copyfile(fullfile(old,name),fullfile(out,name)); end
end
for name=["paper_table_3.txt","paper_table_3.html","paper_table_5.txt"]
 if isfile(fullfile(old,name)); copyfile(fullfile(old,name),fullfile(out,'data',name)); end
end
% Preserve the entire actual optimizer directory, not the author's plots/final archive.
if ~isfolder(fullfile(out,'data','optimizer_checkpoints')); copyfile(meta.history_directory,fullfile(out,'data','optimizer_checkpoints')); end
meaning=["磁体内端沿极轴的定位分量","内侧气隙槽第一定位距离","内侧气隙槽第二定位距离","外侧气隙槽第一边长度","外侧气隙槽第二边长度","永磁体厚度","永磁体长边宽度","V形磁体夹角参数","外侧槽第一边方向角参数","外侧槽第二边方向角参数","极轴附近气隙槽宽度","磁体外端第一延伸距离","磁体外端第二延伸距离","磁体内端第一延伸距离","磁体内端第二延伸距离","磁体内端垂直极轴的定位分量","三相电流初相角 非几何变量"];
source_ref=["point2 and delta","point10","point11","point9 to point14","point7 to point15","point2 to point4","point2 to point3","epsilon and MA1 MA2","phi1","phi2","point12 point23","point3 to point7","point5 to point9","point2 to point6","point4 to point8","gamma delta point2","IGA_EXCcurrentSine_OPT Phase0"];
params=table(); native=struct;
for k=1:numel(P)
 name=string(P(k).Name); base=P(k).Init; if isfield(initial_model_parameters,name); base=initial_model_parameters.(name); end
 scale=1e3; unit="mm"; native_unit="m";
 if any(name==["MA","RA1","RA2"]); scale=1; unit="deg"; native_unit="deg"; end
 if name=="Phase0"; base=0; scale=180/pi; unit="deg"; native_unit="rad"; end
 initial=base*scale; init_opt=P(k).Init*scale; lower=P(k).Min*scale; upper=P(k).Max*scale; final=P(k).Value*scale; delta=final-initial;
 changed=abs(delta)>1e-7;
 row=table(name,meaning(k),unit,initial,init_opt,lower,upper,final,delta,changed,native_unit,base,P(k).Init,P(k).Min,P(k).Max,P(k).Value,source_ref(k),"local_run",'VariableNames',{'variable','physical_meaning','unit','baseline','optimizer_initial','lower_bound','upper_bound','optimized','change','changed','native_unit','baseline_native','optimizer_initial_native','lower_native','upper_native','optimized_native','definition_source','provenance'});
 params=[params;row]; native.(name)=P(k).Value;
end
writetable(params,fullfile(out,'Parameter_Comparison.csv')); writetable(params,fullfile(out,'data','design_variables.csv'));

save(fullfile(out,'data','design_parameters.mat'),'params','initial_model_parameters','native','meta');
write_json(fullfile(out,'data','initial_model_parameters.json'),initial_model_parameters);
write_json(fullfile(out,'data','optimized_parameters_native.json'),native);
A0=B.magnet_area_m2; A1=E.magnet_area_m2; mean0=B.mean_torque_Nm; mean1=summary.mean_torque_Nm; std0=B.torque_std_Nm; std1=summary.torque_std_Nm;
area_reduction_pct=100*(A0-A1)/A0; std_reduction_pct=100*(std0-std1)/std0; mean_change_pct=100*(mean1-mean0)/mean0;
performance=table(["magnet_area_quarter";"mean_torque_full";"torque_std_full"],["mm2";"Nm";"Nm"],[A0*1e6;mean0;std0],[A1*1e6;mean1;std1],[-area_reduction_pct;mean_change_pct;-std_reduction_pct],[area_reduction_pct;NaN;std_reduction_pct],repmat("local_run",3,1),'VariableNames',{'metric','unit','initial','optimized','change_pct','reduction_pct','provenance'});
writetable(performance,fullfile(out,'Performance_Comparison.csv')); writetable(performance,fullfile(out,'data','performance_comparison.csv'));
angle_deg=B.angles_deg(:); initial_full_Nm=B.torque_full_Nm(:); optimized_full_Nm=E.torque_full_Nm(:);
torques=table(angle_deg,initial_full_Nm,optimized_full_Nm,repmat("local_run",30,1),'VariableNames',{'angle_deg','initial_full_Nm','optimized_full_Nm','provenance'});
writetable(torques,fullfile(out,'data','torque_profiles.csv')); save(fullfile(out,'data','torque_profiles.mat'),'torques');
R0=H(1).Responses; n0=vertcat(R0.Name); optimizer_initial_mean_Nm=4*R0(n0=="TorqueMEAN").Value; optimizer_initial_std_Nm=4*R0(n0=="TorqueSTD").Value;
run_summary=summary; run_summary.area_reduction_pct=area_reduction_pct; run_summary.std_reduction_pct=std_reduction_pct; run_summary.mean_change_pct=mean_change_pct; run_summary.baseline_mean_Nm=mean0; run_summary.baseline_std_Nm=std0; run_summary.baseline_area_m2=A0; run_summary.optimizer_initial_mean_Nm=optimizer_initial_mean_Nm; run_summary.optimizer_initial_std_Nm=optimizer_initial_std_Nm; run_summary.optimizer_initial_objective=H(1).fval; run_summary.final_objective=meta.solver_status.objective_final; run_summary.total_baseline_optimization_evaluation_s=B.elapsed_s+meta.elapsed_s+summary.evaluation_elapsed_s; run_summary.optimization_solver_elapsed_s=H(end).TimeElapsed; run_summary.scope='parameter_optimization_only';
write_json(fullfile(out,'data','run_summary.json'),run_summary);
iterations=[H.iteration]'; fvals=[H.fval]'; areas=zeros(numel(H),1); means=areas; stds=areas;
for k=1:numel(H)
 R=H(k).Responses; rn=vertcat(R.Name); areas(k)=R(rn=="Cost").Value*1e6; means(k)=R(rn=="TorqueMEAN").Value*4; stds(k)=R(rn=="TorqueSTD").Value*4;
end
history=table(iterations,fvals,areas,means,stds,[H.constrviolation]',[H.firstorderopt]',[H.funccount]',[H.TimeElapsed]',repmat("local_run",numel(H),1),'VariableNames',{'iteration','weighted_objective','magnet_area_quarter_mm2','mean_torque_full_Nm','torque_std_full_Nm','constraint_violation','first_order_optimality','function_evaluations','elapsed_s','provenance'});
writetable(history,fullfile(out,'data','convergence_history.csv')); save(fullfile(out,'data','convergence_history.mat'),'history','H');
% All convergence metrics come from real callbacks; duplicate callback records are preserved in CSV.
[~,unique_ix]=unique(iterations,'stable'); hx=iterations(unique_ix);
set(groot,'defaultFigureVisible','off'); set(groot,'defaultAxesFontSize',11); set(groot,'defaultAxesFontName','Arial');
blue=[0 .36 .65]; orange=[.85 .33 .10];
% Native geometry surfaces: identical scale, axes and plotting limits. No field re-solve here.
g0=mp_geo_read_nurbs(fullfile(out,'data','baseline_rotor.txt')); g1=mp_geo_read_nurbs(fullfile(out,'data','final_design','final_rotor.txt')); gs=mp_geo_read_nurbs(fullfile(out,'data','baseline_stator.txt'));
opt0=B.opts; opt0.draw_geometry=false; [~,patchR]=GEO_IPMrotor_V_1(opt0); [~,patchS]=GEO_DISstator_2(opt0);
f=figure('Position',[80 80 1100 520]); t=tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; draw_geometry(vertcat(g0.nurbs),vertcat(gs.nurbs),patchR,patchS); title('Initial geometry');
nexttile; draw_geometry(vertcat(g1.nurbs),vertcat(gs.nurbs),patchR,patchS); title('Parameter optimized geometry');
sgtitle('Motor geometry comparison | provenance=local_run'); save_figure(f,out,'Fig1_Geometry_Comparison'); close(f);
f=figure('Position',[80 80 650 650]); draw_geometry(vertcat(g0.nurbs),vertcat(gs.nurbs),patchR,patchS); xlim([0 105]); ylim([0 105]); title('Initial quarter motor | provenance=local_run'); save_figure(f,out,'FigS2_Initial_Full_Model'); close(f);
f=figure('Position',[80 80 850 450]); plot(hx,fvals(unique_ix),'-','Color',blue,'LineWidth',1.7); grid on; xlabel('Iteration'); ylabel('Weighted objective f (scaled)'); title('Parameter optimization convergence | local_run'); save_figure(f,out,'Fig2_Objective_Convergence'); close(f);
f=figure('Position',[80 80 900 480]); plot(angle_deg,initial_full_Nm,'-o','Color',blue,'LineWidth',1.6,'MarkerSize',4); hold on; plot(angle_deg,optimized_full_Nm,'-s','Color',orange,'LineWidth',1.6,'MarkerSize',4); grid on; xlim([0 29]); xlabel('Rotor angle (deg)'); ylabel('Electromagnetic torque, full motor (N m)'); legend('Initial','Parameter optimized','Location','southoutside','Orientation','horizontal'); title('Recomputed torque profiles | provenance=local_run'); save_figure(f,out,'Fig3_Torque_Comparison'); close(f);
f=figure('Position',[80 80 850 450]); plot(hx,areas(unique_ix),'Color',blue,'LineWidth',1.7); hold on; yline(A0*1e6,'--','Initial'); grid on; xlabel('Iteration'); ylabel('Permanent magnet area, quarter model (mm^2)'); title('Recorded magnet area history | provenance=local_run'); save_figure(f,out,'Fig4_Magnet_Area_History'); close(f);
f=figure('Position',[80 80 850 450]); plot(hx,stds(unique_ix),'Color',blue,'LineWidth',1.7); grid on; xlabel('Iteration'); ylabel('Torque population std, full motor (N m)'); title('Recorded torque standard deviation | provenance=local_run'); save_figure(f,out,'Fig5_Torque_Std_History'); close(f);
f=figure('Position',[80 80 1100 620]); tiledlayout(1,2,'TileSpacing','compact');
for panel=1:2
 nexttile; if panel==1; ix=params.unit=="mm" & params.changed; unit='mm'; else; ix=params.unit=="deg" & params.changed; unit='deg'; end
 names=params.variable(ix); v0=params.baseline(ix); v1=params.optimized(ix); y=(1:numel(names))';
 for k=1:numel(y); line([v0(k),v1(k)],[y(k),y(k)],'Color',[.7 .7 .7],'LineWidth',1.4); end
 hold on; a=scatter(v0,y,45,blue,'o','filled'); b=scatter(v1,y,45,orange,'s','filled');
 set(gca,'YTick',y,'YTickLabel',names,'TickLabelInterpreter','none','YDir','reverse'); ylim([.3 numel(names)+.7]); xlabel(['Parameter value (' unit ')']); grid on; legend([a b],{'Initial','Optimized'},'Location','southoutside');
end
sgtitle('Changed design parameters | provenance=local_run'); save_figure(f,out,'Fig6_Parameter_Comparison'); close(f);
% Supplement: constraint behavior is necessary to interpret a non-monotone objective.
f=figure('Position',[80 80 850 620]); tiledlayout(2,1,'TileSpacing','compact');
nexttile; plot(hx,means(unique_ix),'LineWidth',1.6); hold on; yline(summary.torque_target_Nm,'--','Target'); ylabel('Mean full torque (N m)'); grid on;
nexttile; plot(hx,history.constraint_violation(unique_ix),'LineWidth',1.6); xlabel('Iteration'); ylabel('Scaled max violation'); grid on;
sgtitle('Constraint history | provenance=local_run'); save_figure(f,out,'FigS1_Constraint_History'); close(f);
% The exact nine geometry constraints are reevaluated from final actual parameters.
constraints=table((1:numel(E.cgeo))',E.cgeo(:),E.cgeo(:)/100,E.cgeo(:)<=1e-6,'VariableNames',{'index','scaled_value_c_le_zero','distance_residual_m','satisfied_at_solver_tolerance'}); constraints.provenance=repmat("local_run",height(constraints),1); writetable(constraints,fullfile(out,'data','geometry_constraints.csv'));
ref=table(["magnet_area_quarter_m2";"mean_torque_full_Nm";"torque_std_full_Nm";"objective";"iterations";"evaluations";"time_s"],[.0001591;2.3;.0996;4.081;51;65;2100],[A1;mean1;std1;run_summary.final_objective;summary.iterations;summary.func_count;H(end).TimeElapsed],repmat("paper_reference",7,1),repmat("local_run",7,1),'VariableNames',{'metric','paper_parameter_reference','local_result','reference_provenance','local_provenance'}); ref.relative_error_pct=100*(ref.local_result-ref.paper_parameter_reference)./ref.paper_parameter_reference; writetable(ref,fullfile(out,'data','paper_parameter_comparison.csv'));
fprintf('PARAMETER_PACKAGE_SUCCESS: %s\n',out);
end
function draw_geometry(rotor,stator,pr,ps)
hold on;
for region=1:2
 if region==1; surfaces=rotor; patches=pr; else; surfaces=stator; patches=ps; end
 for k=1:numel(surfaces)
  s=surfaces(k); s.coefs(1:3,:,:)=s.coefs(1:3,:,:)*1000;
  color=[.72 .72 .72]; if ismember(k,patches.Air); color=[.85 .95 1]; elseif isfield(patches,'Magnets') && ismember(k,patches.Magnets); color=[.22 .65 .46]; elseif ismember(k,patches.Windings); color=[.88 .38 .27]; end
  nrbplotcol(s,[7 7],'color',color);
 end
end
view(2); axis equal; xlim([0 55]); ylim([0 55]); xlabel('x (mm)'); ylabel('y (mm)'); box on;
end
function save_figure(f,out,name)
savefig(f,fullfile(out,'figures',[name '.fig']));
exportgraphics(f,fullfile(out,'figures',[name '.png']),'Resolution',300);
exportgraphics(f,fullfile(out,'figures',[name '.pdf']),'ContentType','vector');
end
function write_json(path,data)
fid=fopen(path,'w','n','UTF-8'); assert(fid>0); fprintf(fid,'%s',jsonencode(data,PrettyPrint=true)); fclose(fid);
end

function defaults=geometry_defaults(function_name)
source=fileread(which(function_name));
p=strfind(source,'if nargin == 1'); assert(~isempty(p)); source=source(1:p(1)-1);
values=regexp(source,'(?m)^\s*([A-Z][A-Z0-9_]*)\s*=\s*([-+0-9.eE]+)\s*;','tokens');
defaults=struct; for k=1:numel(values); defaults.(values{k}{1})=str2double(values{k}{2}); end
end
