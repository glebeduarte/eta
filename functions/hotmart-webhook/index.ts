// =============================================================
// ETA — Escola de Tecnologias Assistidas
// Edge Function: hotmart-webhook
//
// Recebe eventos do Hotmart e cria/cancela matrículas no Supabase.
// Deploy: supabase functions deploy hotmart-webhook
//
// Variáveis de ambiente necessárias (Supabase > Project Settings > Edge Functions):
//   HOTMART_SECRET   — token de validação do webhook (Hotmart > Ferramentas > Webhooks)
//   SUPABASE_URL     — URL do projeto Supabase (preenchida automaticamente)
//   SUPABASE_SERVICE_ROLE_KEY — chave de serviço (preenchida automaticamente)
// =============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Mapeamento: Hotmart product ID → slug do curso no Supabase
// Preencher com os IDs reais após criar os produtos no Hotmart
const PRODUCT_MAP: Record<string, string> = {
  // "12345": "afo-neurologica",
  // "12346": "afo-pediatrica",
  // "12347": "orto-membro-superior",
  // "12348": "ia-clinica-reabilitacao",
};

serve(async (req: Request) => {
  // Aceita apenas POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Valida token Hotmart
  const token = req.headers.get("x-hotmart-webhook-token");
  const expectedToken = Deno.env.get("HOTMART_SECRET");
  if (!expectedToken || token !== expectedToken) {
    console.error("Webhook: token inválido");
    return new Response("Unauthorized", { status: 401 });
  }

  // Parse do body
  let event: HotmartEvent;
  try {
    event = await req.json();
  } catch {
    return new Response("Bad request: JSON inválido", { status: 400 });
  }

  console.log("Hotmart event:", event.event, "| transaction:", event.data?.purchase?.transaction);

  // Supabase com service role (bypass RLS para inserir enrollment)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  const purchase = event.data?.purchase;
  const buyer = event.data?.buyer;

  if (!purchase || !buyer) {
    return new Response("OK: evento sem dados de compra", { status: 200 });
  }

  const transaction = purchase.transaction;
  const email = buyer.email?.toLowerCase();
  const name = buyer.name;
  const productId = String(purchase.product?.id ?? "");

  // Resolve o slug do curso
  const courseSlug = PRODUCT_MAP[productId];
  if (!courseSlug) {
    console.warn(`Produto não mapeado: ${productId}`);
    return new Response("OK: produto não mapeado", { status: 200 });
  }

  // Busca o course_id pelo slug
  const { data: course, error: courseErr } = await supabase
    .from("courses")
    .select("id")
    .eq("slug", courseSlug)
    .single();

  if (courseErr || !course) {
    console.error("Curso não encontrado:", courseSlug);
    return new Response("Erro interno: curso não encontrado", { status: 500 });
  }

  // Garante que o usuário existe no Auth (cria via invite se necessário)
  let userId: string;
  const { data: users } = await supabase.auth.admin.listUsers();
  const existing = users?.users.find((u) => u.email === email);

  if (existing) {
    userId = existing.id;
  } else {
    // Convida o aluno — ele define a senha no primeiro acesso
    const { data: invited, error: inviteErr } = await supabase.auth.admin.inviteUserByEmail(email, {
      data: { full_name: name },
    });
    if (inviteErr || !invited.user) {
      console.error("Erro ao criar usuário:", inviteErr);
      return new Response("Erro interno: falha ao criar usuário", { status: 500 });
    }
    userId = invited.user.id;
  }

  // Trata eventos de compra, cancelamento e reembolso
  const eventType = event.event;

  if (["PURCHASE_COMPLETE", "PURCHASE_APPROVED"].includes(eventType)) {
    // Cria ou reativa a matrícula
    const { error } = await supabase.from("enrollments").upsert(
      {
        user_id: userId,
        course_id: course.id,
        status: "active",
        hotmart_transaction: transaction,
        enrolled_at: new Date().toISOString(),
        expires_at: null, // vitalício por padrão
      },
      { onConflict: "user_id,course_id" }
    );
    if (error) {
      console.error("Erro ao criar matrícula:", error);
      return new Response("Erro interno ao criar matrícula", { status: 500 });
    }
    console.log(`Matrícula criada: ${email} → ${courseSlug}`);

  } else if (["PURCHASE_REFUNDED", "PURCHASE_CANCELLED", "PURCHASE_CHARGEBACK"].includes(eventType)) {
    // Cancela a matrícula
    const { error } = await supabase
      .from("enrollments")
      .update({ status: "cancelled" })
      .eq("user_id", userId)
      .eq("course_id", course.id);
    if (error) {
      console.error("Erro ao cancelar matrícula:", error);
      return new Response("Erro interno ao cancelar matrícula", { status: 500 });
    }
    console.log(`Matrícula cancelada: ${email} → ${courseSlug}`);
  }

  return new Response("OK", { status: 200 });
});

// -------------------------
// Tipos
// -------------------------
interface HotmartEvent {
  event: string;
  version: string;
  data: {
    purchase?: {
      transaction: string;
      status: string;
      product?: { id: number; name: string };
    };
    buyer?: {
      name: string;
      email: string;
    };
  };
}
