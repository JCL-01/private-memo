import subprocess, sys, datetime, html, pathlib
repo = sys.argv[1]; out = sys.argv[2]
here = pathlib.Path(__file__).parent
md = (pathlib.Path(repo) / 'docs/PRD.md').read_text()
assert '</script' not in md.lower()
git = lambda *a: subprocess.check_output(['git', '-C', repo, *a], text=True).strip()
branch = git('branch', '--show-current'); commit = git('log', '-1', '--format=%h')
updated = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).strftime('%Y-%m-%d %H:%M KST')
t = (here / 'template.html').read_text()
t = t.replace('__BRANCH__', html.escape(branch)).replace('__COMMIT__', commit).replace('__UPDATED__', updated).replace('__MARKDOWN__', md)
pathlib.Path(out).write_text(t)
print('ok', branch, commit, len(t))
