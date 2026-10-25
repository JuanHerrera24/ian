# Arma index.html (invitación) y panel.html (panel de los papás) incrustando
# las imágenes y la música de fuente/media, y los datos de Supabase.
# Uso (desde la carpeta IAN):  python fuente/construir.py
import base64, json, os

aqui = os.path.dirname(os.path.abspath(__file__))
media = os.path.join(aqui, 'media')

archivos = {
    '{{POSTER}}': ('poster.webp', 'image/webp'),
    '{{RETRATO}}': ('retrato.jpg', 'image/jpeg'),
    '{{FOTO1}}': ('foto1.jpg', 'image/jpeg'),
    '{{FOTO2}}': ('foto2.jpg', 'image/jpeg'),
    '{{FOTO3}}': ('foto3.jpg', 'image/jpeg'),
    '{{MUSICA}}': ('musica.mp3', 'audio/mpeg'),
}

# URL del proyecto y clave pública (publishable/anon) de Supabase
with open(os.path.join(aqui, 'supabase-config.json'), encoding='utf-8') as f:
    supa = json.load(f)


def armar(plantilla, salida):
    html = open(os.path.join(aqui, plantilla), encoding='utf-8').read()
    for marca, (nombre, tipo) in archivos.items():
        if marca in html:
            with open(os.path.join(media, nombre), 'rb') as f:
                html = html.replace(marca, 'data:%s;base64,%s' % (tipo, base64.b64encode(f.read()).decode()))
    html = html.replace('{{SUPABASE_URL}}', supa['url'].rstrip('/')).replace('{{SUPABASE_KEY}}', supa['key'])
    ruta = os.path.join(aqui, '..', salida)
    with open(ruta, 'w', encoding='utf-8', newline='\n') as f:
        f.write(html)
    print('Listo:', os.path.normpath(ruta), round(len(html) / 1e6, 2), 'MB')


armar('plantilla.html', 'index.html')
armar('panel-plantilla.html', 'panel.html')
