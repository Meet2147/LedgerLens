// Homepage: the LedgerLens macOS download landing page. All styles are scoped under
// `.ll-root` (via CSS nesting) so they never collide with globals.css, and the markup is
// injected as raw HTML so it keeps plain `class`/`href` attributes. The existing SiteHeader
// (from app/layout.js) sits above this; /converter, /pricing, /login are unchanged.

export const metadata = {
  title: "LedgerLens — Convert Bank Statements to Excel & CSV, on your Mac",
  description:
    "Download LedgerLens for macOS. Turn PDF bank statements into clean CSV/XLSX rows — 100% on-device, nothing uploaded. First 5 statements free."
};

const STYLES = `
.ll-root {
  --base:#e6ebf3; --text:#3b4453; --text-dim:#828da1; --text-faint:#aab3c2;
  --accent:#4f7df6; --accent-2:#2fb6dd; --credit:#1f9a6b; --debit:#d6503b;
  --shadow-dark:rgba(163,177,198,.55); --shadow-light:rgba(255,255,255,.9);
  --inset-dark:rgba(163,177,198,.5);
  background:var(--base); color:var(--text); min-height:100vh; overflow-x:hidden;
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  line-height:1.6; -webkit-font-smoothing:antialiased;

  & * { box-sizing:border-box; margin:0; padding:0; }
  & a { color:inherit; text-decoration:none; }
  & .wrap { max-width:1080px; margin:0 auto; padding:0 24px; }

  & .raised { background:var(--base); border-radius:22px; box-shadow:8px 8px 18px var(--shadow-dark), -8px -8px 18px var(--shadow-light); }
  & .inset { background:var(--base); border-radius:18px; box-shadow:inset 5px 5px 11px var(--inset-dark), inset -5px -5px 11px var(--shadow-light); }
  & .pill { display:inline-flex; align-items:center; gap:7px; padding:8px 15px; border-radius:30px; font-size:13px; font-weight:600; background:var(--base); box-shadow:4px 4px 9px var(--shadow-dark), -4px -4px 9px var(--shadow-light); }
  & .grad-text { background:linear-gradient(120deg,var(--accent),var(--accent-2)); -webkit-background-clip:text; background-clip:text; -webkit-text-fill-color:transparent; }

  & .btn { display:inline-flex; align-items:center; justify-content:center; gap:10px; padding:15px 26px; border-radius:15px; font-size:15px; font-weight:700; cursor:pointer; border:none; transition:transform .12s ease, box-shadow .12s ease; background:var(--base); color:var(--text); box-shadow:6px 6px 14px var(--shadow-dark), -6px -6px 14px var(--shadow-light); }
  & .btn:hover { transform:translateY(-1px); }
  & .btn:active { box-shadow:inset 4px 4px 9px var(--inset-dark), inset -4px -4px 9px var(--shadow-light); transform:translateY(0); }
  & .btn-primary { background:linear-gradient(120deg,var(--accent),var(--accent-2)); color:#fff; }
  & .btn .sub { font-size:11px; font-weight:500; opacity:.85; }

  & .hero { text-align:center; padding:70px 0 60px; }
  & .hero h1 { font-size:clamp(34px,6vw,58px); line-height:1.08; letter-spacing:-1.5px; font-weight:800; margin:26px 0 18px; }
  & .hero p.lead { font-size:clamp(16px,2.4vw,20px); color:var(--text-dim); max-width:620px; margin:0 auto 34px; }
  & .hero-cta { display:flex; gap:16px; justify-content:center; flex-wrap:wrap; align-items:center; }
  & .badges { display:flex; gap:12px; justify-content:center; flex-wrap:wrap; margin-top:30px; }
  & .badges .pill { color:var(--credit); }

  & .mock { margin:56px auto 0; max-width:860px; padding:18px; }
  & .mock-inner { border-radius:14px; overflow:hidden; }
  & .mock-bar { display:flex; gap:8px; padding:14px 16px; }
  & .mock-bar span { width:12px; height:12px; border-radius:50%; }
  & .dot-r { background:#ff5f57; } & .dot-y { background:#febc2e; } & .dot-g { background:#28c840; }
  & .mock-body { padding:4px 20px 22px; }
  & .row { display:grid; grid-template-columns:96px 1fr 90px 100px; gap:10px; padding:11px 6px; font-size:13px; align-items:center; border-bottom:1px solid var(--inset-dark); }
  & .row.head { color:var(--text-faint); font-size:10.5px; font-weight:700; letter-spacing:.6px; border-bottom:1px solid var(--shadow-dark); }
  & .row .num { text-align:right; font-variant-numeric:tabular-nums; font-family:ui-monospace,"SF Mono",Menlo,monospace; }
  & .row .deb { color:var(--debit); } & .row .bal { color:var(--text); font-weight:600; }
  & .row .desc { color:var(--text); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  & .row .date { color:var(--text-dim); font-family:ui-monospace,"SF Mono",Menlo,monospace; }

  & section { padding:66px 0; }
  & .sec-head { text-align:center; margin-bottom:46px; }
  & .sec-head .eyebrow { font-size:13px; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:var(--accent); }
  & .sec-head h2 { font-size:clamp(28px,4vw,40px); letter-spacing:-1px; font-weight:800; margin-top:12px; }
  & .sec-head p { color:var(--text-dim); max-width:560px; margin:14px auto 0; font-size:17px; }

  & .grid { display:grid; gap:26px; }
  & .grid-3 { grid-template-columns:repeat(3,1fr); }
  & .grid-4 { grid-template-columns:repeat(4,1fr); }

  & .feature { padding:30px 26px; }
  & .feature .ic { width:52px; height:52px; border-radius:15px; display:grid; place-items:center; font-size:24px; margin-bottom:18px; }
  & .feature h3 { font-size:18px; margin-bottom:8px; letter-spacing:-.3px; }
  & .feature p { color:var(--text-dim); font-size:14.5px; }

  & .step { padding:30px 26px; text-align:center; }
  & .step .n { width:46px; height:46px; border-radius:50%; display:grid; place-items:center; margin:0 auto 16px; font-weight:800; font-size:18px; color:var(--accent); }
  & .step h3 { font-size:17px; margin-bottom:6px; }
  & .step p { color:var(--text-dim); font-size:14px; }

  & .plan { padding:30px 24px; display:flex; flex-direction:column; gap:6px; position:relative; }
  & .plan .name { font-size:15px; font-weight:700; color:var(--text-dim); }
  & .plan .price { font-size:40px; font-weight:800; letter-spacing:-1.5px; margin:6px 0 2px; }
  & .plan .price small { font-size:15px; font-weight:600; color:var(--text-dim); letter-spacing:0; }
  & .plan .tag { font-size:13px; color:var(--text-dim); min-height:20px; }
  & .plan ul { list-style:none; margin:18px 0 22px; display:flex; flex-direction:column; gap:9px; }
  & .plan li { font-size:13.5px; display:flex; gap:9px; align-items:flex-start; }
  & .plan li::before { content:"✓"; color:var(--credit); font-weight:800; }
  & .plan .btn { width:100%; margin-top:auto; }
  & .plan.featured::after { content:"BEST VALUE"; position:absolute; top:-11px; left:50%; transform:translateX(-50%); background:linear-gradient(120deg,var(--accent),var(--accent-2)); color:#fff; font-size:10px; font-weight:800; letter-spacing:.6px; padding:4px 12px; border-radius:20px; }
  & .biz-note { text-align:center; margin-top:30px; color:var(--text-dim); font-size:14px; }

  & .dl { padding:46px; text-align:center; max-width:720px; margin:0 auto; }
  & .dl h2 { font-size:30px; letter-spacing:-.8px; margin-bottom:10px; }
  & .dl p { color:var(--text-dim); margin-bottom:26px; }
  & .dl .meta { margin-top:22px; font-size:12.5px; color:var(--text-faint); }
  & .dl .meta code { font-family:ui-monospace,Menlo,monospace; word-break:break-all; }

  & .ll-footer { padding:50px 0 60px; text-align:center; color:var(--text-faint); font-size:13px; }
  & .ll-footer .fbrand { display:flex; align-items:center; gap:10px; justify-content:center; margin-bottom:14px; }
}
@media (prefers-color-scheme: dark) {
  .ll-root {
    --base:#23262c; --text:#dce1e9; --text-dim:#8a93a2; --text-faint:#5b636f;
    --accent:#5e8bff; --accent-2:#46d2f0; --credit:#45d9a0; --debit:#ff8674;
    --shadow-dark:rgba(0,0,0,.55); --shadow-light:rgba(255,255,255,.045);
    --inset-dark:rgba(0,0,0,.5);
  }
}
@media (max-width:880px){ .ll-root .grid-3, .ll-root .grid-4 { grid-template-columns:1fr 1fr; } }
@media (max-width:560px){ .ll-root .grid-3, .ll-root .grid-4 { grid-template-columns:1fr; } }
`;

const MARKUP = `
<section class="hero" id="ll-top">
  <div class="wrap">
    <span class="pill" style="color:var(--credit)">🔒 100% on-device · nothing uploaded</span>
    <h1>Bank statement PDFs,<br /><span class="grad-text">turned into spreadsheets.</span></h1>
    <p class="lead">Drop in your PDF bank statements and get clean, ready-to-use CSV or XLSX rows — parsed entirely on your Mac. Your statements never leave your computer.</p>
    <div class="hero-cta">
      <a class="btn btn-primary" href="/LedgerLens.dmg" download>
        <span style="font-size:20px">↓</span>
        <span style="text-align:left">Download for macOS<span class="sub" style="display:block">Free · Apple notarized</span></span>
      </a>
      <a class="btn" href="#ll-pricing">See pricing</a>
    </div>
    <div class="badges">
      <span class="pill">✨ First 5 statements free</span>
      <span class="pill">📄 CSV + XLSX export</span>
      <span class="pill">🏦 Multi-bank parsing</span>
    </div>
    <div class="mock raised">
      <div class="mock-inner inset">
        <div class="mock-bar"><span class="dot-r"></span><span class="dot-y"></span><span class="dot-g"></span></div>
        <div class="mock-body">
          <div class="row head"><span>DATE</span><span>DESCRIPTION</span><span class="num">DEBIT</span><span class="num">BALANCE</span></div>
          <div class="row"><span class="date">01/06/2026</span><span class="desc">UPI/COMPASS IN/cf.compassindi/NSDL</span><span class="num deb">45.00</span><span class="num bal">32,363.05</span></div>
          <div class="row"><span class="date">01/06/2026</span><span class="desc">UPI/Zepto/zeptoonline@yb/YES BANK</span><span class="num deb">499.00</span><span class="num bal">31,834.05</span></div>
          <div class="row"><span class="date">03/06/2026</span><span class="desc">UPI/AWS India/amazonaws@rapl/Amazon</span><span class="num deb">833.98</span><span class="num bal">30,950.07</span></div>
          <div class="row"><span class="date">05/06/2026</span><span class="desc">BIL/Personal Loan XX65396 EMI</span><span class="num deb">25,967.00</span><span class="num bal">4,716.07</span></div>
          <div class="row" style="border-bottom:none"><span class="date">06/06/2026</span><span class="desc">UPI/ZOMATO/payzomato@hdfc/HDFC</span><span class="num deb">500.09</span><span class="num bal">1,719.98</span></div>
        </div>
      </div>
    </div>
  </div>
</section>

<section id="ll-features">
  <div class="wrap">
    <div class="sec-head">
      <div class="eyebrow">Why LedgerLens</div>
      <h2>Built for statements you can't upload</h2>
      <p>Financial data is sensitive. LedgerLens does the whole job locally — no account, no cloud, no compromise.</p>
    </div>
    <div class="grid grid-3">
      <div class="feature raised"><div class="ic inset">🔒</div><h3>Fully on-device</h3><p>Every PDF is opened and parsed on your Mac. Nothing is uploaded — the app doesn't send your data anywhere.</p></div>
      <div class="feature raised"><div class="ic inset">🏦</div><h3>Multi-bank templates</h3><p>Auto-detects statement layouts and extracts date, description, debit, credit and balance — reconciled to the penny.</p></div>
      <div class="feature raised"><div class="ic inset">📊</div><h3>CSV &amp; XLSX export</h3><p>One click to a clean spreadsheet your accountant or bookkeeping tool can import immediately.</p></div>
      <div class="feature raised"><div class="ic inset">🗂️</div><h3>Batch conversion</h3><p>Drop a whole folder of statements at once and export them together, tagged by source file.</p></div>
      <div class="feature raised"><div class="ic inset">🔑</div><h3>Password-protected PDFs</h3><p>Locked statement? Enter the password and LedgerLens unlocks and parses it locally.</p></div>
      <div class="feature raised"><div class="ic inset">🌓</div><h3>Light &amp; dark</h3><p>A calm neumorphic interface that adapts to your system — or lock it to light or dark.</p></div>
    </div>
  </div>
</section>

<section id="ll-how">
  <div class="wrap">
    <div class="sec-head"><div class="eyebrow">How it works</div><h2>Three steps to a spreadsheet</h2></div>
    <div class="grid grid-3">
      <div class="step raised"><div class="n inset">1</div><h3>Add statements</h3><p>Drag in one or more PDF bank statements, or browse to them.</p></div>
      <div class="step raised"><div class="n inset">2</div><h3>Convert</h3><p>LedgerLens extracts every transaction locally in seconds.</p></div>
      <div class="step raised"><div class="n inset">3</div><h3>Export</h3><p>Review the rows and save to CSV or XLSX. Done.</p></div>
    </div>
  </div>
</section>

<section id="ll-pricing">
  <div class="wrap">
    <div class="sec-head">
      <div class="eyebrow">Pricing</div>
      <h2>Start free. Upgrade when it pays for itself.</h2>
      <p>Your first 5 statements are free — no account needed. After that, pick the plan that fits.</p>
    </div>
    <div class="grid grid-4">
      <div class="plan raised"><span class="name">Monthly</span><div class="price">$7<small>/mo</small></div><div class="tag">Cancel anytime</div><ul><li>Unlimited conversions</li><li>CSV + XLSX export</li><li>Batch PDFs</li></ul><a class="btn" href="https://buy.polar.sh/polar_cl_2aWIgE5WYJaaY1kmhD7i0tQx3i4661C0AgpAU2jnjBq">Choose Monthly</a></div>
      <div class="plan raised"><span class="name">Yearly</span><div class="price">$59<small>/yr</small></div><div class="tag">Save ~30% vs monthly</div><ul><li>Everything in Monthly</li><li>Two months free</li><li>Priority updates</li></ul><a class="btn" href="https://buy.polar.sh/polar_cl_Yd9JYxJra1oQdNzoHYG4rFpGLnX5VlVgmc0xb1PUo8x">Choose Yearly</a></div>
      <div class="plan raised featured"><span class="name">Lifetime</span><div class="price">$99<small>once</small></div><div class="tag">Pay once, own forever</div><ul><li>Everything, forever</li><li>All future updates</li><li>No subscription</li></ul><a class="btn btn-primary" href="https://buy.polar.sh/polar_cl_kJrdPRW9FF64ttGwYz0wqYd0diZfAew6McP3y1EmzNY">Get Lifetime</a></div>
      <div class="plan raised"><span class="name">Firm</span><div class="price">$29<small>/mo</small></div><div class="tag">For firms &amp; teams</div><ul><li>Up to 25 seats</li><li>For many clients</li><li>Everything in Pro</li></ul><a class="btn" href="https://buy.polar.sh/polar_cl_bd6Ly3fkUldjOW6zB7BccMUs2tUbuliNq3nST2wCUGl">Choose Firm</a></div>
    </div>
    <p class="biz-note">Every plan unlocks Pro via a license key you activate right in the app. Secure checkout by Polar.</p>
  </div>
</section>

<section id="ll-download">
  <div class="wrap">
    <div class="dl raised">
      <img src="/assets/logo.png" alt="" style="width:78px;height:78px;border-radius:20px;margin-bottom:18px" />
      <h2>Download LedgerLens</h2>
      <p>Free to try — your first 5 statements are on us. Signed &amp; notarized by Apple.</p>
      <div class="hero-cta" style="justify-content:center">
        <a class="btn btn-primary" href="/LedgerLens.dmg" download>
          <span style="font-size:20px"></span>
          <span style="text-align:left">Download for macOS<span class="sub" style="display:block">.dmg · macOS 13+ · 1.5 MB · notarized</span></span>
        </a>
        <a class="btn" href="https://github.com/Meet2147/LedgerLens" style="opacity:.9">
          <span style="font-size:20px">⊞</span>
          <span style="text-align:left">Windows<span class="sub" style="display:block">Coming soon</span></span>
        </a>
      </div>
      <div class="meta">Apple notarized · Developer ID: Meet Jethwa<br />SHA-256: <code>b49022125bb613355f90eebf81eb9e107f56ab4425aedbcab44a67b603cbfccb</code></div>
    </div>
  </div>
</section>

<footer class="ll-footer">
  <div class="wrap">
    <div class="fbrand"><img src="/assets/logo_small.png" alt="" style="width:34px;height:34px;border-radius:10px" /><b style="color:var(--text)">LedgerLens</b></div>
    <p>Turn bank statement PDFs into spreadsheets — privately, on your Mac.</p>
  </div>
</footer>
`;

export default function HomePage() {
  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: STYLES }} />
      <div className="ll-root" dangerouslySetInnerHTML={{ __html: MARKUP }} />
    </>
  );
}
