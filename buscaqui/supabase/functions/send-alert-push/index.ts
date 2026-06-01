// Edge Function: send-alert-push
// Disparada quando um alerta é inserido (trigger pg_net). Busca os tokens FCM
// do responsável/passageiro do aluno e envia push via FCM HTTP v1.
//
// Variáveis de ambiente necessárias (Project Settings > Edge Functions):
//   FIREBASE_SERVICE_ACCOUNT  -> JSON da service account do Firebase (string)
//   EDGE_SHARED_SECRET        -> segredo compartilhado com o trigger do banco
// (SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são injetadas automaticamente.)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input;
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(body);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

// deno-lint-ignore no-explicit-any
async function getAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claim))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`Falha ao obter access token: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

Deno.serve(async (req: Request) => {
  try {
    // Auth do webhook por segredo compartilhado.
    const secret = Deno.env.get("EDGE_SHARED_SECRET");
    if (secret && req.headers.get("x-edge-secret") !== secret) {
      return new Response("unauthorized", { status: 401 });
    }

    const { alerta_id } = await req.json();
    if (!alerta_id) {
      return new Response("alerta_id ausente", { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Alerta -> passageiro -> responsável; reúne os usuario_id destinatários.
    const { data: alerta } = await supabase
      .from("alertas")
      .select("mensagem, passageiro_id")
      .eq("id", alerta_id)
      .single();
    if (!alerta) return new Response("alerta não encontrado", { status: 404 });

    const { data: passageiro } = await supabase
      .from("passageiros")
      .select("usuario_id, responsaveis(usuario_id)")
      .eq("id", alerta.passageiro_id)
      .single();

    const destinatarios = new Set<string>();
    if (passageiro?.usuario_id) destinatarios.add(passageiro.usuario_id);
    // deno-lint-ignore no-explicit-any
    const resp = (passageiro as any)?.responsaveis;
    if (resp?.usuario_id) destinatarios.add(resp.usuario_id);

    if (destinatarios.size === 0) {
      return new Response(JSON.stringify({ enviados: 0, motivo: "sem destinatários" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: tokens } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("usuario_id", [...destinatarios]);

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ enviados: 0, motivo: "sem tokens" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let enviados = 0;
    for (const { token } of tokens) {
      const r = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: "BusCaqui", body: alerta.mensagem },
            data: { alerta_id: String(alerta_id), tipo: "alerta" },
            android: { priority: "high" },
          },
        }),
      });
      if (r.ok) enviados++;
    }

    return new Response(JSON.stringify({ enviados }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
