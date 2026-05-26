const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || '';
const FROM_EMAIL = 'Construccion Oholey Jinuj <noreply@oholeyconstruye.com.ar>';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' } });
  }

  try {
    const { to, donante, status, compromiso, pagado, currency, donante_id } = await req.json();

    const statusLabel: Record<string, string> = {
      confirmado: 'Confirmado ✓',
      reservado: 'Reservado',
      proceso: 'En proceso',
      negociacion: 'En negociación',
    };

    const fmt = (v: number) => Math.round(v).toLocaleString('es-AR');
    const saldo = (compromiso || 0) - (pagado || 0);
    const cur = currency || 'USD';

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px">
        <div style="background:#1a2540;padding:16px 20px;border-radius:10px 10px 0 0">
          <h2 style="color:#f5c048;margin:0;font-size:18px">CEOJ — Actualización de donación</h2>
        </div>
        <div style="border:1px solid #e2e8f0;border-top:none;padding:20px;border-radius:0 0 10px 10px">
          <p style="color:#1a2540;font-size:14px">Hola <strong>${donante}</strong>,</p>
          <p style="color:#374151;font-size:13px">Tu donación fue actualizada:</p>
          <table style="width:100%;border-collapse:collapse;margin:12px 0">
            <tr style="background:#f8fafc">
              <td style="padding:8px 12px;font-size:12px;color:#64748b">Estado</td>
              <td style="padding:8px 12px;font-size:13px;font-weight:700;color:#1a2540">${statusLabel[status] || status}</td>
            </tr>
            <tr>
              <td style="padding:8px 12px;font-size:12px;color:#64748b">Comprometido</td>
              <td style="padding:8px 12px;font-size:13px;color:#1a2540">${cur} ${fmt(compromiso)}</td>
            </tr>
            <tr style="background:#f8fafc">
              <td style="padding:8px 12px;font-size:12px;color:#64748b">Pagado</td>
              <td style="padding:8px 12px;font-size:13px;color:#059669;font-weight:600">${cur} ${fmt(pagado)}</td>
            </tr>
            <tr>
              <td style="padding:8px 12px;font-size:12px;color:#64748b">Saldo pendiente</td>
              <td style="padding:8px 12px;font-size:13px;color:#c8880a;font-weight:600">${cur} ${fmt(saldo)}</td>
            </tr>
          </table>
          <p style="color:#94a3b8;font-size:11px;margin-top:16px">Centro Educativo Oholey Jinuj — Etapa 2<br>Tucumán 3177 / Agüero 841, CABA</p>
          ${donante_id ? `<p style="margin-top:16px;padding-top:12px;border-top:1px solid #e2e8f0;font-size:10px;color:#cbd5e1;text-align:center"><a href="https://czsqbdjlptcgkxrrfceu.supabase.co/functions/v1/unsubscribe?id=${donante_id}" style="color:#cbd5e1">No deseo recibir más notificaciones</a></p>` : ''}
        </div>
      </div>`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: FROM_EMAIL, to: [to], subject: `Actualización de tu donación — CEOJ`, html }),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Error Resend');

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }
});
