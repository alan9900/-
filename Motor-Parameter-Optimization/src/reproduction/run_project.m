function run_project(action)
% Parameter-only portable entry. Published results are never overwritten.
arguments
    action (1,:) char {mustBeMember(action,{'environment','validate','baseline','optimize','evaluate','figures'})}
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
scripts=fullfile(root,'src','reproduction'); out=fullfile(root,'runtime');
addpath(scripts);
if strcmp(action,'validate')
    validate_results(root); return;
end
if strcmp(action,'environment')
    run(fullfile(scripts,'inspect_environment.m')); return;
end
assert(isfile(fullfile(out,'work','results','opt_param','opt_param.m')), ...
    'Run src/reproduction/Bootstrap-Upstream.ps1 first.');
for d=["auxiliary","classes","derivatives","geometries","operators","packages"]
    addpath(genpath(fullfile(out,'work',d)));
end
for d=["data","figures","logs"]
    if ~isfolder(fullfile(out,d)); mkdir(fullfile(out,d)); end
end
original_directory=pwd; cleanup=onCleanup(@() cd(original_directory)); %#ok<NASGU>
switch action
    case 'baseline'
        if isfile(fullfile(out,'data','baseline.mat'))
            fprintf('Reusing runtime baseline; no computation restarted.\n'); return;
        end
        diary(fullfile(out,'logs','baseline.log')); diary_cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
        run_stage('baseline');
    case 'optimize'
        assert(~isfile(fullfile(out,'data','param_opt.mat')), ...
            'Saved optimization exists. Preserve it; use a clean checkout for a new experiment.');
        if ~isfile(fullfile(out,'data','baseline.mat')); run_project('baseline'); end
        diary(fullfile(out,'logs','param_opt.log')); diary_cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
        run_stage('param');
    case {'evaluate','figures'}
        if ~isfile(fullfile(out,'data','param_opt.mat'))
            import_published_results(root,out);
        end
        if strcmp(action,'evaluate')
            diary(fullfile(out,'logs','param_reevaluation.log')); diary_cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
            evaluate_final('param');
        else
            assert(isfile(fullfile(out,'data','param_summary.json')), 'Evaluate the final design first.');
            package_parameter_results();
        end
end
end

function import_published_results(root,out)
source=fullfile(root,'results','data');
for name=["baseline.mat","param_opt.mat","param_evaluation.mat","param_evaluation_raw.mat", ...
        "param_summary.json","param_reevaluation_check.csv","baseline_rotor.txt","baseline_stator.txt"]
    copyfile(fullfile(source,name),fullfile(out,'data',name));
end
copyfile(fullfile(source,'final_design'),fullfile(out,'data','param'));
copyfile(fullfile(source,'optimizer_checkpoints'),fullfile(out,'data','optimizer_checkpoints'));
path=fullfile(out,'data','param','final_metadata.mat'); metadata=load(path);
metadata.history_directory=string(fullfile(out,'data','optimizer_checkpoints'));
save(path,'-struct','metadata');
fprintf('Imported published local_run data; no optimizer started.\n');
end

function validate_results(root)
data=fullfile(root,'results','data');
B=load(fullfile(data,'baseline.mat')); E=load(fullfile(data,'param_evaluation.mat'));
raw=load(fullfile(data,'param_evaluation_raw.mat'));
S=jsondecode(fileread(fullfile(data,'run_summary.json')));
assert(isequal(B.angles_deg(:),E.angles_deg(:)) && isequal(B.angles_deg(:),(0:29)'));
assert(abs(mean(E.torque_full_Nm)-S.mean_torque_Nm)<1e-12);
assert(abs(std(E.torque_full_Nm,1)-S.torque_std_Nm)<1e-12);
assert(numel(raw.angles)==121 && all(raw.residual_squared<1e-6));
P=readtable(fullfile(data,'Parameter_Comparison.csv'));
assert(height(P)==17 && all(P.optimized_native>=P.lower_native & P.optimized_native<=P.upper_native));
H=load(fullfile(data,'param_opt.mat'));
assert(numel(H.OptimizationHistory)==53 && H.OptimizationHistory(end).iteration==51);
assert(E.summary.exitflag==2 && S.constraint_max_violation<=1e-6);
for k=1:6
    fig=dir(fullfile(root,'results','figures',sprintf('Fig%d_*.fig',k))); assert(numel(fig)==1);
    f=openfig(fullfile(fig.folder,fig.name),'invisible'); assert(isgraphics(f)); close(f);
end
fprintf('PUBLICATION_VALIDATION_PASSED: MAT, CSV, 30/121 angles, population std, bounds, 53 callbacks, 6 editable FIGs.\n');
end
