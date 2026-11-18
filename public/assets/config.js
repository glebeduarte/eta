// Configuração pública da ETA (chave anon é pública por design; o acesso é controlado por RLS)
window.ETA_CONFIG = {
  SUPABASE_URL: 'https://gayfopqjkfpnkekcwfdx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdheWZvcHFqa2Zwbmtla2N3ZmR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1MDk5MDksImV4cCI6MjExMDA4NTkwOX0.uPtdbD5KcW29w-ynyrIRQ7gGk7QlSTWw3c_-NauGQW0',
  // Panda Vídeo: base do player embed da sua biblioteca, ex.:
  // 'https://player-vz-xxxxxxxx-xxx.tv.pandavideo.com.br/embed/?v='
  PANDA_EMBED_BASE: ''
};
window.eta = window.supabase.createClient(window.ETA_CONFIG.SUPABASE_URL, window.ETA_CONFIG.SUPABASE_ANON_KEY);

window.etaUtil = {
  esc(s) { return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); },
  hours(min) { if (!min) return ''; const h = Math.floor(min / 60), m = min % 60; return h ? (m ? `${h}h${String(m).padStart(2,'0')}` : `${h}h`) : `${m} min`; },
  plural(n, s, p) { return `${n} ${n === 1 ? s : p}`; },
  coverStyle(c) {
    return c.cover_url
      ? `background-image:url('${c.cover_url}')`
      : `background-image:linear-gradient(145deg,#12061a,#1f0d2a)`;
  }
};
