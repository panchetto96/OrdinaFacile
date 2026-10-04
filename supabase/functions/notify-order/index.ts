// Avvisa il titolare quando arriva un nuovo ordine.
// Collegata a un Database Webhook di Supabase su INSERT in public.orders.
// Variabili richieste: RESEND_API_KEY, ORDER_EMAIL_TO, ORDER_EMAIL_FROM.
// (Le notifiche push via Firebase si aggiungono qui quando il progetto Firebase è pronto.)
import { createClient } from "npm:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const fmtEuro = (n: number) =>
  new Intl.NumberFormat("it-IT", { style: "currency", currency: "EUR" }).format(n);

const esc = (s: string) =>
  String(s ?? "").replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[ch]!);

const unitLabel: Record<string, string> = { kg: "kg", etto: "hg", pz: "pz", lt: "lt", ct: "ct" };

Deno.serve(async (req) => {
  const payload = await req.json();
  const orderId = payload?.record?.id;
  if (!orderId) return new Response("nessun ordine", { status: 400 });

  // Il webhook parte all'INSERT dell'ordine: le righe vengono inserite nella
  // stessa transazione, quindi qui sono già leggibili.
  const { data: order, error } = await supabase
    .from("orders")
    .select("id, note, total, created_at, profiles(business_name, username, phone, address), order_items(product_name, unit, unit_price, quantity)")
    .eq("id", orderId)
    .single();
  if (error || !order) return new Response(error?.message ?? "non trovato", { status: 500 });

  const c = order.profiles as any;
  const rows = (order.order_items as any[])
    .map((i) => `<tr><td>${esc(i.product_name)}</td><td>${i.quantity} ${unitLabel[i.unit]}</td><td>${fmtEuro(i.unit_price * i.quantity)}</td></tr>`)
    .join("");

  const html = `
    <h2>Nuovo ordine #${order.id}</h2>
    <p><b>${esc(c.business_name || c.username)}</b><br>${esc(c.address)}<br>Tel. ${esc(c.phone)}</p>
    <table border="1" cellpadding="6" cellspacing="0">
      <tr><th>Prodotto</th><th>Quantità</th><th>Importo stimato</th></tr>${rows}
    </table>
    <p><b>Totale stimato: ${fmtEuro(order.total)}</b></p>
    ${order.note ? `<p>Note: ${esc(order.note)}</p>` : ""}`;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("ORDER_EMAIL_FROM"),
      to: Deno.env.get("ORDER_EMAIL_TO"),
      subject: `Nuovo ordine #${order.id} da ${c.business_name || c.username}`,
      html,
    }),
  });

  return new Response(await res.text(), { status: res.ok ? 200 : 502 });
});
