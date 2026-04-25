export function BrandMark({ className = "brand-mark", title = "LedgerLens" }) {
  return (
    <svg
      aria-label={title}
      className={className}
      role="img"
      viewBox="0 0 64 64"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id="ledgerlens-gradient" x1="0%" x2="100%" y1="0%" y2="100%">
          <stop offset="0%" stopColor="#0d6b57" />
          <stop offset="100%" stopColor="#d98b41" />
        </linearGradient>
      </defs>
      <rect fill="url(#ledgerlens-gradient)" height="56" rx="18" width="56" x="4" y="4" />
      <path
        d="M21 18h8v24h18v8H21V18Z"
        fill="#fffaf2"
      />
      <path
        d="M36 18h8v15h-8z"
        fill="#fffaf2"
        opacity="0.86"
      />
      <circle cx="44" cy="42" fill="#1f2421" opacity="0.12" r="9" />
      <circle cx="44" cy="42" fill="none" r="6.5" stroke="#fffaf2" strokeWidth="3" />
      <path
        d="M48.8 46.8 53 51"
        fill="none"
        stroke="#fffaf2"
        strokeLinecap="round"
        strokeWidth="3"
      />
    </svg>
  );
}
