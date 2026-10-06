// Cancella le foto degli ordini più vecchie di 60 giorni dallo spazio `ordini-foto`.
// Chiamata ogni notte da pg_cron (migrazione 0012). Deploy senza verifica JWT:
// può solo eliminare foto già scadute, quindi una chiamata in più non fa danni.
import { createClient } from "npm:@supabase/supabase-js@2";

const GIORNI = 60;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async () => {
  const cutoff = new Date(Date.now() - GIORNI * 24 * 60 * 60 * 1000).toISOString();
  const { data: orders, error } = await supabase
    .from("orders")
    .select("id, photo_path")
    .not("photo_path", "is", null)
    .is("photo_removed_at", null)
    .lt("created_at", cutoff)
    .limit(500);
  if (error) return new Response(error.message, { status: 500 });
  if (!orders.length) return Response.json({ eliminate: 0 });

  const { error: rmError } = await supabase.storage
    .from("ordini-foto")
    .remove(orders.map((o) => o.photo_path as string));
  if (rmError) return new Response(rmError.message, { status: 500 });

  const { error: upError } = await supabase
    .from("orders")
    .update({ photo_removed_at: new Date().toISOString() })
    .in("id", orders.map((o) => o.id));
  if (upError) return new Response(upError.message, { status: 500 });

  return Response.json({ eliminate: orders.length });
});
