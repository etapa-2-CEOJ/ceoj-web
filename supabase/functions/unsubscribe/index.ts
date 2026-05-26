const SB_URL = 'https://czsqbdjlptcgkxrrfceu.supabase.co';
const SB_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const id = url.searchParams.get('id');

  if (!id) {
    return new Response(html('Error', 'El enlace no es válido.'), { headers: { 'Content-Type': 'text/html' } });
  }

  const res = await fetch(`${SB_URL}/rest/v1/donantes?id=eq.${id}`, {
    method: 'PATCH',
    headers: {
      'apikey': SB_KEY,
      'Authorization': `Bearer ${SB_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email_unsub: true }),
  });

  if (!res.ok) {
    return new Response(html('Error', 'No se pudo procesar la solicitud. Por favor contactanos directamente.'), { headers: { 'Content-Type': 'text/html' } });
  }

  return new Response(html('Baja registrada', 'Tu solicitud fue procesada. Ya no recibirás notificaciones de pago.<br><br>Si esto fue un error, podés contactarnos a <a href="mailto:info@oholeyconstruye.com.ar" style="color:#b8860b">info@oholeyconstruye.com.ar</a>.'), { headers: { 'Content-Type': 'text/html' } });
});

function html(title: string, body: string): string {
  return `<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title} — CEOJ</title>
<style>body{font-family:Arial,sans-serif;background:#f1f5f9;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
.box{background:#fff;border-radius:12px;padding:40px 32px;max-width:420px;text-align:center;box-shadow:0 4px 24px rgba(0,0,0,.08)}
h2{color:#1a2540;margin:0 0 12px}p{color:#475569;font-size:14px;line-height:1.6}</style></head>
<body><div class="box"><h2>${title}</h2><p>${body}</p>
<p style="margin-top:24px;font-size:12px;color:#94a3b8">Centro Educativo Oholey Jinuj — Etapa 2</p></div></body></html>`;
}
