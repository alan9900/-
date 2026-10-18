function finalize_existing(scenario)
assert(any(strcmp(scenario,{'baseline','param'})), 'Only baseline and parameter optimization are supported.');
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); out=fullfile(root,'runtime'); work=fullfile(out,'work');
for d=["auxiliary","classes","derivatives","geometries","operators","packages"]; addpath(genpath(fullfile(work,d))); end
addpath(fullfile(root,'src','reproduction'));
stage_dir=fullfile(out,'data',scenario); if ~isfolder(stage_dir); mkdir(stage_dir); end
if ~isfile(fullfile(stage_dir,'final_metadata.mat'))
 raw=load(fullfile(out,'data',[scenario '_opt.mat']));
 H=raw.OptimizationHistory; opts_final=raw.opts; parameters=H(end).Parameters;
 assert(max(abs(vertcat(parameters.Value)-raw.xopt))<1e-12,'Returned design differs from final callback');
 for k=1:numel(parameters); opts_final.(parameters(k).Name)=raw.xopt(k); end
 if ~isfield(opts_final,'Phase0'); opts_final.Phase0=0; end
 dirs=dir(fullfile(work,'results',['opt_' scenario],'plots','*','solver_status.mat'));
 assert(~isempty(dirs)); [~,i]=max([dirs.datenum]); history_directory=string(dirs(i).folder);
 solver_status=load(fullfile(history_directory,'solver_status.mat'));
 iteration=H(end).iteration;
 copyfile(fullfile(history_directory,['RotorOpt' num2str(iteration) '.txt']),fullfile(stage_dir,'final_rotor.txt'));
 copyfile(fullfile(history_directory,['StatorOpt' num2str(iteration) '.txt']),fullfile(stage_dir,'final_stator.txt'));
 constraints=H(end).Constraints;
 for k=1:numel(constraints)
  if constraints(k).Name=="TorqueMEAN"
   constraints(k).Value=2.3/4;
  else
   constraints(k).Value=0;
  end
 end
 objectives=H(end).Objectives; elapsed_s=raw.elapsed_s;
 started=NaT;
 save(fullfile(stage_dir,'final_metadata.mat'),'opts_final','parameters','constraints','objectives','solver_status','history_directory','started','elapsed_s');
end
evaluate_final(scenario);
end
