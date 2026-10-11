"""Servidor local con fallback SPA para la compilación Flutter Web."""
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8080)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent / 'build' / 'web'
if not (root / 'index.html').exists():
    raise SystemExit('Ejecuta flutter build web antes de iniciar el servidor.')

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(root), **kw)

    def do_GET(self):
        path = root / self.path.split('?')[0].lstrip('/')
        if not path.is_file() and '.' not in path.name:
            self.path = '/index.html'
        super().do_GET()

print(f'UNSA LAB: http://127.0.0.1:{args.port}', flush=True)
ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
