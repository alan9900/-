function prepare_publication()
% Normalize location metadata in publication copies only; never change numbers.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
data=fullfile(root,'results','data');
path=fullfile(data,'param_evaluation.mat'); s=load(path);
s.summary.source_file='results/data/final_design/final_rotor.txt'; save(path,'-struct','s');
path=fullfile(data,'final_design','final_metadata.mat'); s=load(path);
s.history_directory="results/data/optimizer_checkpoints"; save(path,'-struct','s');
path=fullfile(data,'design_parameters.mat'); s=load(path);
s.meta.history_directory="results/data/optimizer_checkpoints"; save(path,'-struct','s');
fprintf('Publication metadata normalized. Numerical arrays retained.\n');
end
