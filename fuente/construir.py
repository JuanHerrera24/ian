# Arma index.html (invitación) y panel.html (panel de los papás), y copia las
# imágenes y la música de fuente/media a la carpeta assets.
# Los HTML deben pesar poco: WhatsApp no genera la vista previa de páginas muy pesadas.
# Uso (desde la carpeta IAN):  python fuente/construir.py
import json, os, shutil

aqui = os.path.dirname(os.path.abspath(__file__))
media = os.path.join(aqui, 'media')
raiz = os.path.normpath(os.path.join(aqui, '..'))
assets = os.path.join(raiz, 'assets')

archivos = {
    '{{POSTER}}': 'poster.webp',
    '{{RETRATO}}': 'retrato.jpg',
    '{{FOTO1}}': 'foto1.jpg',
    '{{FOTO2}}': 'foto2.jpg',
    '{{FOTO3}}': 'foto3.jpg',
    '{{MUSICA}}': 'musica.mp3',
}

# URL del proyecto y clave pública (publishable/anon) de Supabase
with open(os.path.join(aqui, 'supabase-config.json'), encoding='utf-8') as f:
    supa = json.load(f)

os.makedirs(assets, exist_ok=True)
for nombre in archivos.values():
    shutil.copyfile(os.path.join(media, nombre), os.path.join(assets, nombre))


def armar(plantilla, salida):
    html = open(os.path.join(aqui, plantilla), encoding='utf-8').read()
    for marca, nombre in archivos.items():
        html = html.replace(marca, 'assets/' + nombre)
    html = html.replace('{{SUPABASE_URL}}', supa['url'].rstrip('/')).replace('{{SUPABASE_KEY}}', supa['key'])
    ruta = os.path.join(raiz, salida)
    with open(ruta, 'w', encoding='utf-8', newline='\n') as f:
        f.write(html)
    print('Listo:', ruta, round(len(html.encode('utf-8')) / 1024), 'KB')


armar('plantilla.html', 'index.html')
armar('panel-plantilla.html', 'panel.html')
