"""Read-only independent audit of the published MATLAB results (Python 3)."""
from pathlib import Path
import csv, hashlib, json, re
import numpy as np
from scipy.io import loadmat
from PIL import Image

root = Path(__file__).resolve().parents[2]
data = root / 'results/data'
summary = json.loads((data / 'run_summary.json').read_text(encoding='utf-8'))
baseline = loadmat(data / 'baseline.mat', simplify_cells=True)
final = loadmat(data / 'param_evaluation.mat', simplify_cells=True)
raw = loadmat(data / 'param_evaluation_raw.mat', simplify_cells=True)
assert np.array_equal(baseline['angles_deg'], np.arange(30))
assert np.array_equal(final['angles_deg'], baseline['angles_deg'])
torque = final['torque_full_Nm']
assert np.isfinite(torque).all() and len(torque) == 30
assert abs(np.mean(torque) - summary['mean_torque_Nm']) < 1e-12
assert abs(np.std(torque, ddof=0) - summary['torque_std_Nm']) < 1e-12
assert len(raw['angles']) == 121 and np.all(raw['residual_squared'] < 1e-6)
assert summary['mean_torque_Nm'] >= 2.3 and summary['constraint_max_violation'] == 0
def rows(path):
    with path.open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))
def exact_case_exists(path):
    # Windows exists() accepts mismatched case; GitHub URL paths do not.
    cursor=path.anchor and Path(path.anchor) or Path('.')
    for part in path.parts:
        if part in {path.anchor,'.'}: continue
        if part=='..': cursor=cursor.parent; continue
        if not cursor.is_dir() or part not in {entry.name for entry in cursor.iterdir()}:
            return False
        cursor=cursor/part
    return cursor.exists()
parameters = rows(data / 'Parameter_Comparison.csv')
assert len(parameters) == 17
for p in parameters:
    assert float(p['lower_native']) <= float(p['optimized_native']) <= float(p['upper_native'])
history = rows(data / 'convergence_history.csv')
assert len(history) == 53 and float(history[-1]['iteration']) == 51
assert float(history[-1]['function_evaluations']) == 72
assert abs(float(history[-1]['weighted_objective']) - summary['final_objective']) < 1e-12
for path in data.rglob('*.mat'):
    assert loadmat(path), str(path)
for png in (root / 'results/figures').glob('*.png'):
    with Image.open(png) as image:
        image.verify()
    assert png.with_suffix('.fig').stat().st_size > 1000
    assert png.with_suffix('.pdf').stat().st_size > 1000
for md in root.rglob('*.md'):
    if 'runtime' in md.relative_to(root).parts or md.name == 'UPSTREAM_README.md':
        continue
    for link in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',md.read_text(encoding='utf-8')):
        if not re.match(r'https?://',link):
            assert exact_case_exists(md.parent / link.split('#')[0]), f'{md}: {link}'
manifest = root / 'docs/FILE_MANIFEST.csv'
if manifest.exists():
    for item in rows(manifest):
        assert exact_case_exists(root / item['path']), item['path']
        content = (root / item['path']).read_bytes()
        assert len(content) == int(item['bytes'])
        assert hashlib.sha256(content).hexdigest() == item['sha256'], item['path']
print(json.dumps({'status':'passed','all_mat_readable':True,'all_png_readable':True,
    'parameters':17,'callback_records':53,'iterations':51,'function_evaluations':72,
    'population_std_verified':True,'bounds_feasible':True,'field_residuals_feasible':True,
    'markdown_links_valid_including_case':True,'hash_manifest_verified':manifest.exists()},ensure_ascii=False,indent=2))
