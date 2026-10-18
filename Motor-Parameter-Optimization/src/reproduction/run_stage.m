function run_stage(scenario)
assert(any(strcmp(scenario,{'baseline','param'})), 'Only baseline and parameter optimization are supported.');
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
out = fullfile(root,'runtime'); work = fullfile(out,'work');
restoredefaultpath;
for d = ["auxiliary","classes","derivatives","geometries","operators","packages"]
 addpath(genpath(fullfile(work,d)));
end
addpath(fullfile(root,'src','reproduction'));
set(groot,'defaultFigureVisible','off');
started = datetime('now','TimeZone','Asia/Shanghai'); timer = tic;
fprintf('LOCAL_RUN scenario=%s started=%s\n',scenario,string(started));
try
 if strcmp(scenario,'baseline')
  cd(fullfile(work,'results','opt_evaluations'));
  run('eval_init.m');
  angles_full = angles; torque_quarter_full = T;
  ix = ismember(angles,0:29); angles = angles(ix); T = T(ix);
  assert(numel(T)==30 && all(isfinite(T)));
  magnet_area_m2 = sum([Rotor.Geometry(patchesRotor.Magnets).Area]);
  torque_full_Nm = 4*T(:); angles_deg = angles(:);
  provenance = 'local_run'; elapsed_s = toc(timer);
  source_file = 'results/opt_evaluations/eval_init.m';
  mean_torque_Nm = mean(torque_full_Nm); torque_std_Nm = std(torque_full_Nm,1);
  save(fullfile(out,'data','baseline.mat'),'angles_full','torque_quarter_full','angles_deg','torque_full_Nm','magnet_area_m2','mean_torque_Nm','torque_std_Nm','provenance','elapsed_s','source_file','opts');
  metrics = table(string(scenario),"partial",string(provenance),mean_torque_Nm,torque_std_Nm,magnet_area_m2,elapsed_s,'VariableNames',{'scenario','status','provenance','mean_torque_Nm','torque_std_Nm','magnet_area_m2','elapsed_s'});
  writetable(metrics,fullfile(out,'data','baseline_metrics.csv'));
  writetable(table(angles_deg,torque_full_Nm),fullfile(out,'data','baseline_torque.csv'));
  nrbexport(Rotor.Surface,fullfile(out,'data','baseline_rotor.txt'));
  nrbexport(Stator.Surface,fullfile(out,'data','baseline_stator.txt'));
  Motor.setRotationAngle(0,'deg'); Motor.plotGeometry();
  xlabel('x (mm)'); ylabel('y (mm)'); title('Initial motor | provenance=local_run');
  exportgraphics(gcf,fullfile(out,'figures','geometry_initial.png'),'Resolution',220);
  fprintf('BASELINE_SUCCESS mean_full=%.12g std_full=%.12g area_quarter=%.12g elapsed_s=%.3f\n',mean_torque_Nm,torque_std_Nm,magnet_area_m2,elapsed_s);
 else
  cd(fullfile(work,'results',['opt_' scenario]));
  run(['opt_' scenario '.m']);
  OptimizationHistory=Motor.OptimizationHistory;
  elapsed_s=toc(timer); provenance='local_run';
  save(fullfile(out,'data',[scenario '_opt.mat']),'xopt','OptimizationHistory','elapsed_s','provenance','opts');
  stage_dir=fullfile(out,'data',scenario); if ~isfolder(stage_dir); mkdir(stage_dir); end
  Motor.optimizationUpdate(xopt);
  nrbexport(Rotor.Surface,fullfile(stage_dir,'final_rotor.txt'));
  nrbexport(Stator.Surface,fullfile(stage_dir,'final_stator.txt'));
  parameters=Motor.OptimizationParameters;
  opts_final=opts;
  for k=1:numel(parameters); parameters(k).Value=xopt(k); opts_final.(parameters(k).Name)=xopt(k); end
  if ~isfield(opts_final,'Phase0'); opts_final.Phase0=0; end
  constraints=Motor.OptimizationConstraints; objectives=Motor.OptimizationObjectives;
  solver_status=load(fullfile(Motor.SaveDirectory,'solver_status.mat'));
  history_directory=string(fullfile(pwd,Motor.SaveDirectory));
  save(fullfile(stage_dir,'final_metadata.mat'),'opts_final','parameters','constraints','objectives','solver_status','history_directory','started','elapsed_s');
  evaluate_final(scenario);
  fprintf('OPTIMIZATION_RETURNED scenario=%s elapsed_s=%.3f\n',scenario,elapsed_s);
 end
catch err
 fprintf(2,'%s\n',getReport(err,'extended','hyperlinks','off'));
 fid=fopen(fullfile(out,'logs',[scenario '_error.txt']),'w'); fprintf(fid,'%s',getReport(err,'extended','hyperlinks','off')); fclose(fid);
 rethrow(err);
end
end
