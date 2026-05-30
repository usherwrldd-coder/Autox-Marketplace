import { useState, useEffect, useRef } from "react";

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
const T = {
  // Colors
  bg: "#080C14",
  bgCard: "#0D1420",
  bgGlass: "rgba(13,20,32,0.75)",
  border: "rgba(255,255,255,0.07)",
  borderHover: "rgba(255,140,0,0.4)",
  gold: "#FF8C00",
  goldLight: "#FFB347",
  goldDark: "#CC6600",
  red: "#FF3B3B",
  green: "#00E676",
  blue: "#00B4FF",
  purple: "#9C6FFF",
  text: "#F0F4FF",
  textMuted: "#8896B0",
  textDim: "#4A5568",
};

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
const CATEGORIES = [
  { id: 1, name: "Engine Parts", icon: "⚙️", count: 12400 },
  { id: 2, name: "Brakes", icon: "🛑", count: 8900 },
  { id: 3, name: "Suspension", icon: "🔩", count: 6700 },
  { id: 4, name: "Exhaust", icon: "💨", count: 5200 },
  { id: 5, name: "Lighting", icon: "💡", count: 9800 },
  { id: 6, name: "Body Kits", icon: "🏎️", count: 4300 },
  { id: 7, name: "Interior", icon: "🪑", count: 7600 },
  { id: 8, name: "Electronics", icon: "📟", count: 11200 },
];

const PRODUCTS = [
  { id: 1, title: "Brembo GT 6-Piston Brake Kit", brand: "Brembo", price: 2800, coins: 2800, condition: "New", category: "Brakes", img: "🔴", rating: 4.9, reviews: 234, vendor: "ProBrake Co.", type: "buy", badge: "Featured", compatible: "BMW M3 2019-2024" },
  { id: 2, title: "HKS GT2 Supercharger System", brand: "HKS", price: 4200, coins: 4200, condition: "New", category: "Engine Parts", img: "🟡", rating: 4.8, reviews: 156, vendor: "JDM Direct", type: "auction", badge: "Hot", compatible: "Toyota Supra A90", timeLeft: "2h 14m", bids: 23 },
  { id: 3, title: "BC Racing Coilover Kit Type BR", brand: "BC Racing", price: 1200, coins: 1200, condition: "New", category: "Suspension", img: "🔵", rating: 4.7, reviews: 412, vendor: "Track Ready", type: "negotiable", badge: "Best Seller", compatible: "Universal" },
  { id: 4, title: "Akrapovič Evolution Exhaust Ti", brand: "Akrapovič", price: 3600, coins: 3600, condition: "New", category: "Exhaust", img: "⚫", rating: 5.0, reviews: 89, vendor: "EU Performance", type: "buy", badge: "Premium", compatible: "Porsche 911 GT3" },
  { id: 5, title: "Recaro Pole Position Seat", brand: "Recaro", price: 1800, coins: 1800, condition: "New", category: "Interior", img: "🟢", rating: 4.9, reviews: 201, vendor: "Race Seats EU", type: "buy", badge: "New", compatible: "Universal FIA" },
  { id: 6, title: "Turbosmart BOV Kompact Dual", brand: "Turbosmart", price: 320, coins: 320, condition: "New", category: "Engine Parts", img: "🟠", rating: 4.6, reviews: 567, vendor: "Boost Kings", type: "negotiable", badge: "", compatible: "Universal" },
  { id: 7, title: "HID Motorsports Xenon Kit H7", brand: "HID MS", price: 189, coins: 189, condition: "New", category: "Lighting", img: "🟤", rating: 4.5, reviews: 890, vendor: "LuxLight", type: "buy", badge: "", compatible: "Universal H7" },
  { id: 8, title: "Bilstein B16 PSS10 Kit", brand: "Bilstein", price: 1650, coins: 1650, condition: "New", category: "Suspension", img: "🔷", rating: 4.8, reviews: 178, vendor: "German Parts", type: "auction", badge: "Ending Soon", compatible: "Audi RS4 B9", timeLeft: "45m", bids: 41 },
];

const VENDORS = [
  { id: 1, name: "JDM Direct", verified: true, rating: 4.9, sales: 12400, flag: "🇯🇵" },
  { id: 2, name: "EU Performance", verified: true, rating: 4.8, sales: 8700, flag: "🇩🇪" },
  { id: 3, name: "ProBrake Co.", verified: true, rating: 4.9, sales: 6200, flag: "🇺🇸" },
  { id: 4, name: "Track Ready", verified: true, rating: 4.7, sales: 9100, flag: "🇬🇧" },
];

const STATS = [
  { label: "Active Listings", value: "284K+", icon: "📦" },
  { label: "Verified Vendors", value: "12K+", icon: "✅" },
  { label: "Happy Buyers", value: "890K+", icon: "🌟" },
  { label: "Coins Transacted", value: "$42M+", icon: "🪙" },
];

// ─── GLOBAL STYLES ────────────────────────────────────────────────────────────
const GS = `
  @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=DM+Sans:wght@300;400;500;600&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #080C14; color: #F0F4FF; font-family: 'DM Sans', sans-serif; overflow-x: hidden; }
  ::-webkit-scrollbar { width: 4px; } 
  ::-webkit-scrollbar-track { background: #080C14; }
  ::-webkit-scrollbar-thumb { background: #FF8C00; border-radius: 2px; }
  
  @keyframes fadeUp { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
  @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.5; } }
  @keyframes glow { 0%,100% { box-shadow: 0 0 20px rgba(255,140,0,0.3); } 50% { box-shadow: 0 0 40px rgba(255,140,0,0.6); } }
  @keyframes spin { to { transform: rotate(360deg); } }
  @keyframes slideIn { from { transform:translateX(-100%); opacity:0; } to { transform:translateX(0); opacity:1; } }
  @keyframes coinFloat { 0%,100% { transform:translateY(0) rotate(0deg); } 50% { transform:translateY(-10px) rotate(180deg); } }
  @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
  @keyframes blink { 0%,100% { opacity:1; } 50% { opacity:0; } }

  .fade-up { animation: fadeUp 0.5s ease forwards; }
  .glow-gold { animation: glow 2s ease-in-out infinite; }
  .coin-float { animation: coinFloat 3s ease-in-out infinite; }

  .shimmer-text {
    background: linear-gradient(90deg, #FF8C00 0%, #FFB347 30%, #FFF8E1 50%, #FFB347 70%, #FF8C00 100%);
    background-size: 200% auto;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    animation: shimmer 3s linear infinite;
  }

  .card-hover {
    transition: all 0.3s cubic-bezier(0.4,0,0.2,1);
  }
  .card-hover:hover {
    transform: translateY(-4px);
    border-color: rgba(255,140,0,0.4) !important;
    box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 30px rgba(255,140,0,0.1);
  }

  .btn-primary {
    background: linear-gradient(135deg, #FF8C00, #FFB347);
    color: #000;
    border: none;
    font-family: 'DM Sans', sans-serif;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }
  .btn-primary:hover {
    background: linear-gradient(135deg, #FFB347, #FFCC80);
    transform: translateY(-1px);
    box-shadow: 0 10px 30px rgba(255,140,0,0.4);
  }

  .btn-ghost {
    background: transparent;
    color: #F0F4FF;
    border: 1px solid rgba(255,255,255,0.15);
    font-family: 'DM Sans', sans-serif;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s;
  }
  .btn-ghost:hover {
    border-color: rgba(255,140,0,0.5);
    color: #FF8C00;
    background: rgba(255,140,0,0.05);
  }

  .glass {
    background: rgba(13,20,32,0.75);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255,255,255,0.07);
  }

  .tag {
    display: inline-flex;
    align-items: center;
    padding: 2px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.5px;
  }
  .tag-gold { background: rgba(255,140,0,0.15); color: #FF8C00; border: 1px solid rgba(255,140,0,0.3); }
  .tag-green { background: rgba(0,230,118,0.1); color: #00E676; border: 1px solid rgba(0,230,118,0.3); }
  .tag-red { background: rgba(255,59,59,0.1); color: #FF3B3B; border: 1px solid rgba(255,59,59,0.3); }
  .tag-blue { background: rgba(0,180,255,0.1); color: #00B4FF; border: 1px solid rgba(0,180,255,0.3); }
  .tag-purple { background: rgba(156,111,255,0.1); color: #9C6FFF; border: 1px solid rgba(156,111,255,0.3); }

  .grid-products {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 20px;
  }

  @media (max-width: 768px) {
    .grid-products { grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
    .hide-mobile { display: none !important; }
    .mobile-full { width: 100% !important; }
  }

  input, select {
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.1);
    color: #F0F4FF;
    font-family: 'DM Sans', sans-serif;
    outline: none;
    transition: border-color 0.2s;
  }
  input:focus, select:focus { border-color: rgba(255,140,0,0.5); }
  input::placeholder { color: #4A5568; }
  select option { background: #0D1420; }

  .sidebar-link {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 16px;
    border-radius: 10px;
    cursor: pointer;
    color: #8896B0;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s;
    border: 1px solid transparent;
  }
  .sidebar-link:hover, .sidebar-link.active {
    background: rgba(255,140,0,0.08);
    color: #FF8C00;
    border-color: rgba(255,140,0,0.2);
  }

  .stat-card {
    background: linear-gradient(135deg, rgba(13,20,32,0.9), rgba(20,30,50,0.9));
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 16px;
    padding: 24px;
    text-align: center;
    transition: all 0.3s;
  }
  .stat-card:hover { border-color: rgba(255,140,0,0.3); transform: translateY(-2px); }

  .auction-timer {
    background: rgba(255,59,59,0.1);
    border: 1px solid rgba(255,59,59,0.3);
    color: #FF3B3B;
    padding: 4px 10px;
    border-radius: 8px;
    font-family: 'Orbitron', monospace;
    font-size: 12px;
    animation: pulse 1s ease-in-out infinite;
  }

  .wallet-card {
    background: linear-gradient(135deg, #1a1200, #2d1f00, #1a1200);
    border: 1px solid rgba(255,140,0,0.3);
    border-radius: 20px;
    padding: 28px;
    position: relative;
    overflow: hidden;
  }
  .wallet-card::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -20%;
    width: 200px;
    height: 200px;
    background: radial-gradient(circle, rgba(255,140,0,0.15), transparent 70%);
    border-radius: 50%;
  }

  .escrow-badge {
    background: linear-gradient(135deg, rgba(156,111,255,0.1), rgba(0,180,255,0.1));
    border: 1px solid rgba(156,111,255,0.3);
    border-radius: 12px;
    padding: 16px;
  }

  .nav-tab {
    padding: 8px 18px;
    border-radius: 10px;
    cursor: pointer;
    font-size: 13px;
    font-weight: 500;
    transition: all 0.2s;
    white-space: nowrap;
  }
  .nav-tab.active {
    background: rgba(255,140,0,0.15);
    color: #FF8C00;
    border: 1px solid rgba(255,140,0,0.3);
  }
  .nav-tab:not(.active) {
    color: #8896B0;
    border: 1px solid transparent;
  }
  .nav-tab:not(.active):hover { color: #F0F4FF; }

  .progress-bar {
    height: 4px;
    background: rgba(255,255,255,0.08);
    border-radius: 2px;
    overflow: hidden;
  }
  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, #FF8C00, #FFB347);
    border-radius: 2px;
    transition: width 0.5s ease;
  }
`;

// ─── COMPONENTS ───────────────────────────────────────────────────────────────

function Navbar({ page, setPage, walletBalance, notifications }) {
  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <nav style={{
      position: "sticky", top: 0, zIndex: 100,
      background: "rgba(8,12,20,0.95)",
      backdropFilter: "blur(20px)",
      borderBottom: "1px solid rgba(255,255,255,0.06)",
      padding: "0 24px",
    }}>
      <div style={{ maxWidth: 1400, margin: "0 auto", display: "flex", alignItems: "center", height: 64, gap: 24 }}>
        {/* Logo */}
        <div onClick={() => setPage("home")} style={{ cursor: "pointer", display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 8,
            background: "linear-gradient(135deg, #FF8C00, #CC4400)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 16, fontWeight: 900, color: "#000",
            fontFamily: "'Orbitron', monospace",
          }}>AX</div>
          <span style={{ fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 16, letterSpacing: 2 }} className="shimmer-text">AUTOX</span>
        </div>

        {/* Search */}
        <div className="hide-mobile" style={{ flex: 1, maxWidth: 500, position: "relative" }}>
          <input placeholder="Search parts, brands, vehicles..." style={{
            width: "100%", padding: "9px 16px 9px 42px",
            borderRadius: 10, fontSize: 13,
          }} />
          <span style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)", fontSize: 14 }}>🔍</span>
        </div>

        {/* Nav Links */}
        <div className="hide-mobile" style={{ display: "flex", alignItems: "center", gap: 4 }}>
          {["home","marketplace","auctions"].map(p => (
            <button key={p} onClick={() => setPage(p)} style={{
              background: page === p ? "rgba(255,140,0,0.1)" : "transparent",
              color: page === p ? "#FF8C00" : "#8896B0",
              border: page === p ? "1px solid rgba(255,140,0,0.25)" : "1px solid transparent",
              padding: "6px 14px", borderRadius: 8, cursor: "pointer",
              fontSize: 13, fontWeight: 500, fontFamily: "'DM Sans', sans-serif",
              transition: "all 0.2s", textTransform: "capitalize",
            }}>{p}</button>
          ))}
        </div>

        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 12 }}>
          {/* Wallet */}
          <button onClick={() => setPage("wallet")} style={{
            display: "flex", alignItems: "center", gap: 6,
            background: "rgba(255,140,0,0.08)", border: "1px solid rgba(255,140,0,0.25)",
            borderRadius: 10, padding: "6px 14px", cursor: "pointer",
            color: "#FF8C00", fontSize: 13, fontWeight: 600,
            fontFamily: "'DM Sans', sans-serif",
          }}>
            <span>🪙</span> <span>{walletBalance.toLocaleString()} AXC</span>
          </button>

          {/* Notif */}
          <div style={{ position: "relative", cursor: "pointer" }} onClick={() => setPage("dashboard")}>
            <div style={{ fontSize: 20 }}>🔔</div>
            {notifications > 0 && (
              <div style={{
                position: "absolute", top: -4, right: -4,
                background: "#FF3B3B", color: "#fff",
                width: 16, height: 16, borderRadius: "50%",
                fontSize: 9, fontWeight: 700,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>{notifications}</div>
            )}
          </div>

          {/* Avatar */}
          <div onClick={() => setPage("dashboard")} style={{
            width: 36, height: 36, borderRadius: "50%",
            background: "linear-gradient(135deg, #FF8C00, #CC4400)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 14, fontWeight: 700, color: "#000", cursor: "pointer",
          }}>JD</div>
        </div>
      </div>
    </nav>
  );
}

function HeroSection({ setPage }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [make, setMake] = useState("");
  const [model, setModel] = useState("");
  const [year, setYear] = useState("");

  return (
    <div style={{
      position: "relative", minHeight: 580, display: "flex", alignItems: "center",
      background: "linear-gradient(135deg, #080C14 0%, #0D1420 50%, #080C14 100%)",
      overflow: "hidden",
    }}>
      {/* BG Effects */}
      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(ellipse 60% 60% at 80% 50%, rgba(255,140,0,0.06) 0%, transparent 70%)",
      }} />
      <div style={{
        position: "absolute", top: "20%", right: "5%", width: 400, height: 400,
        background: "radial-gradient(circle, rgba(255,140,0,0.04) 0%, transparent 70%)",
        borderRadius: "50%", filter: "blur(40px)",
      }} />
      {/* Grid Lines */}
      <div style={{
        position: "absolute", inset: 0, opacity: 0.03,
        backgroundImage: "linear-gradient(rgba(255,255,255,0.5) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.5) 1px, transparent 1px)",
        backgroundSize: "60px 60px",
      }} />

      <div style={{ position: "relative", zIndex: 2, maxWidth: 1400, margin: "0 auto", padding: "60px 24px", width: "100%" }}>
        <div style={{ maxWidth: 680 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
            <span className="tag tag-gold">🏆 #1 Auto Parts Marketplace</span>
            <span className="tag tag-green">✓ Escrow Protected</span>
          </div>
          <h1 style={{
            fontFamily: "'Orbitron', monospace", fontWeight: 900,
            fontSize: "clamp(32px, 5vw, 60px)", lineHeight: 1.1,
            marginBottom: 20, color: "#F0F4FF",
          }}>
            THE WORLD'S<br />
            <span className="shimmer-text">PREMIUM AUTO</span><br />
            PARTS EXCHANGE
          </h1>
          <p style={{ fontSize: 16, color: "#8896B0", lineHeight: 1.7, marginBottom: 32, maxWidth: 500 }}>
            Buy, sell, bid & negotiate on 284K+ verified auto parts. Every transaction escrow-protected with AUTOX Coins.
          </p>

          {/* Search Box */}
          <div className="glass" style={{ borderRadius: 16, padding: 20 }}>
            <div style={{ display: "flex", gap: 10, marginBottom: 12, flexWrap: "wrap" }}>
              <input value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                placeholder="Search parts, brands..." style={{
                  flex: 1, minWidth: 200, padding: "10px 16px", borderRadius: 10, fontSize: 14,
                }} />
              <button className="btn-primary" onClick={() => setPage("marketplace")} style={{
                padding: "10px 24px", borderRadius: 10, fontSize: 14,
              }}>Search 🔍</button>
            </div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              {[
                { placeholder: "Make", options: ["BMW", "Toyota", "Honda", "Ford", "Porsche"], val: make, set: setMake },
                { placeholder: "Model", options: ["M3", "Supra", "Civic", "Mustang", "911"], val: model, set: setModel },
                { placeholder: "Year", options: ["2024","2023","2022","2021","2020","2019"], val: year, set: setYear },
              ].map(s => (
                <select key={s.placeholder} value={s.val} onChange={e => s.set(e.target.value)} style={{
                  flex: 1, minWidth: 100, padding: "8px 12px", borderRadius: 8, fontSize: 13,
                  cursor: "pointer",
                }}>
                  <option value="">{s.placeholder}</option>
                  {s.options.map(o => <option key={o} value={o}>{o}</option>)}
                </select>
              ))}
            </div>
          </div>

          {/* Trust Badges */}
          <div style={{ display: "flex", flexWrap: "wrap", gap: 20, marginTop: 24 }}>
            {[
              { icon: "🛡️", text: "Escrow Protected" },
              { icon: "⚡", text: "Instant Payout" },
              { icon: "🌍", text: "Ship Worldwide" },
              { icon: "💯", text: "Verified Parts" },
            ].map(b => (
              <div key={b.text} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13, color: "#8896B0" }}>
                <span>{b.icon}</span><span>{b.text}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right decoration */}
      <div className="hide-mobile" style={{
        position: "absolute", right: 40, top: "50%", transform: "translateY(-50%)",
        display: "flex", flexDirection: "column", gap: 12, opacity: 0.7,
      }}>
        {[
          { label: "Live Auctions", value: "1,247", color: T.red },
          { label: "Active Listings", value: "284K+", color: T.gold },
          { label: "Verified Vendors", value: "12K+", color: T.green },
        ].map(s => (
          <div key={s.label} className="glass" style={{ padding: "14px 20px", borderRadius: 12, minWidth: 160 }}>
            <div style={{ fontSize: 20, fontFamily: "'Orbitron', monospace", fontWeight: 700, color: s.color }}>{s.value}</div>
            <div style={{ fontSize: 11, color: T.textMuted, marginTop: 2 }}>{s.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function ProductCard({ product, setPage }) {
  const [liked, setLiked] = useState(false);

  const badgeColor = {
    "Featured": "tag-gold", "Hot": "tag-red", "Best Seller": "tag-green",
    "Premium": "tag-purple", "New": "tag-blue", "Ending Soon": "tag-red",
  };

  const emojiBg = {
    "🔴": "#3D1515", "🟡": "#2D2500", "🔵": "#0F1F3D",
    "⚫": "#1A1A1A", "🟢": "#0D2B1A", "🟠": "#2D1800",
    "🟤": "#231A0F", "🔷": "#0F1F3D",
  };

  return (
    <div className="card-hover" style={{
      background: T.bgCard, border: `1px solid ${T.border}`,
      borderRadius: 16, overflow: "hidden", cursor: "pointer",
    }} onClick={() => setPage("product")}>
      {/* Image */}
      <div style={{
        height: 160, background: emojiBg[product.img] || "#1A1A1A",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 64, position: "relative",
      }}>
        <span>{product.img}</span>
        {/* Badge */}
        {product.badge && (
          <div style={{ position: "absolute", top: 10, left: 10 }}>
            <span className={`tag ${badgeColor[product.badge] || "tag-gold"}`}>{product.badge}</span>
          </div>
        )}
        {/* Type badge */}
        <div style={{ position: "absolute", top: 10, right: 10 }}>
          {product.type === "auction" && <span className="tag tag-red">🔨 Auction</span>}
          {product.type === "negotiable" && <span className="tag tag-blue">💬 Offer</span>}
        </div>
        {/* Like */}
        <button onClick={e => { e.stopPropagation(); setLiked(!liked); }} style={{
          position: "absolute", bottom: 10, right: 10,
          background: "rgba(0,0,0,0.5)", border: "none",
          borderRadius: "50%", width: 32, height: 32,
          cursor: "pointer", fontSize: 14, display: "flex",
          alignItems: "center", justifyContent: "center",
        }}>{liked ? "❤️" : "🤍"}</button>
      </div>

      {/* Info */}
      <div style={{ padding: "14px 14px 16px" }}>
        <div style={{ fontSize: 10, color: T.gold, fontWeight: 600, marginBottom: 4, letterSpacing: 0.5 }}>
          {product.brand.toUpperCase()} · {product.category.toUpperCase()}
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, color: T.text, marginBottom: 4, lineHeight: 1.4 }}>
          {product.title}
        </div>
        <div style={{ fontSize: 11, color: T.textMuted, marginBottom: 8 }}>
          🚗 {product.compatible}
        </div>

        {/* Rating */}
        <div style={{ display: "flex", alignItems: "center", gap: 4, marginBottom: 10 }}>
          <span style={{ color: "#FFB347", fontSize: 11 }}>{"★".repeat(Math.floor(product.rating))}</span>
          <span style={{ fontSize: 11, color: T.textMuted }}>{product.rating} ({product.reviews})</span>
        </div>

        {/* Auction info */}
        {product.type === "auction" && (
          <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
            <span className="auction-timer">⏱ {product.timeLeft}</span>
            <span style={{ fontSize: 11, color: T.textMuted }}>{product.bids} bids</span>
          </div>
        )}

        {/* Price */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, color: T.gold, fontFamily: "'Orbitron', monospace" }}>
              {product.coins.toLocaleString()} AXC
            </div>
            <div style={{ fontSize: 10, color: T.textMuted }}>${product.price.toLocaleString()} USD</div>
          </div>
          <button className="btn-primary" onClick={e => { e.stopPropagation(); setPage("product"); }} style={{
            padding: "7px 14px", borderRadius: 8, fontSize: 11,
          }}>
            {product.type === "auction" ? "Bid Now" : product.type === "negotiable" ? "Offer" : "Buy Now"}
          </button>
        </div>

        {/* Vendor */}
        <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px solid ${T.border}`, fontSize: 11, color: T.textMuted }}>
          🏪 {product.vendor} · <span style={{ color: T.green }}>✓ Escrow</span>
        </div>
      </div>
    </div>
  );
}

// ─── PAGE: HOME ──────────────────────────────────────────────────────────────
function HomePage({ setPage, walletBalance, setWalletBalance }) {
  return (
    <div>
      <HeroSection setPage={setPage} />

      {/* Stats */}
      <div style={{ maxWidth: 1400, margin: "0 auto", padding: "48px 24px 0" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 16, marginBottom: 56 }}>
          {STATS.map((s, i) => (
            <div key={s.label} className="stat-card" style={{ animationDelay: `${i * 0.1}s` }}>
              <div style={{ fontSize: 28, marginBottom: 8 }}>{s.icon}</div>
              <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 24, fontWeight: 700, color: T.gold }}>{s.value}</div>
              <div style={{ fontSize: 13, color: T.textMuted, marginTop: 4 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Categories */}
        <div style={{ marginBottom: 56 }}>
          <SectionHeader title="Shop by Category" action="View All" onAction={() => setPage("marketplace")} />
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(140px, 1fr))", gap: 12, marginTop: 20 }}>
            {CATEGORIES.map(cat => (
              <div key={cat.id} onClick={() => setPage("marketplace")} className="card-hover" style={{
                background: T.bgCard, border: `1px solid ${T.border}`,
                borderRadius: 14, padding: "16px 12px", textAlign: "center", cursor: "pointer",
              }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>{cat.icon}</div>
                <div style={{ fontSize: 12, fontWeight: 600, color: T.text, marginBottom: 4 }}>{cat.name}</div>
                <div style={{ fontSize: 10, color: T.textMuted }}>{cat.count.toLocaleString()} listings</div>
              </div>
            ))}
          </div>
        </div>

        {/* Featured Products */}
        <div style={{ marginBottom: 56 }}>
          <SectionHeader title="Trending Parts" action="Browse All" onAction={() => setPage("marketplace")} />
          <div className="grid-products" style={{ marginTop: 20 }}>
            {PRODUCTS.slice(0, 4).map(p => <ProductCard key={p.id} product={p} setPage={setPage} />)}
          </div>
        </div>

        {/* Auctions */}
        <div style={{ marginBottom: 56 }}>
          <SectionHeader title="🔨 Live Auctions" action="All Auctions" onAction={() => setPage("auctions")} />
          <div className="grid-products" style={{ marginTop: 20 }}>
            {PRODUCTS.filter(p => p.type === "auction").map(p => <ProductCard key={p.id} product={p} setPage={setPage} />)}
          </div>
        </div>

        {/* Escrow Banner */}
        <EscrowBanner />

        {/* Vendors */}
        <div style={{ marginBottom: 56, marginTop: 48 }}>
          <SectionHeader title="Top Verified Vendors" action="All Vendors" />
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 16, marginTop: 20 }}>
            {VENDORS.map(v => (
              <div key={v.id} className="card-hover" style={{
                background: T.bgCard, border: `1px solid ${T.border}`,
                borderRadius: 16, padding: 20, cursor: "pointer",
              }} onClick={() => setPage("vendor")}>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
                  <div style={{
                    width: 48, height: 48, borderRadius: 12,
                    background: "linear-gradient(135deg, #FF8C00, #CC4400)",
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 20,
                  }}>{v.flag}</div>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: 14 }}>{v.name}</div>
                    {v.verified && <span className="tag tag-green" style={{ marginTop: 2 }}>✓ Verified</span>}
                  </div>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: T.textMuted }}>
                  <span>⭐ {v.rating}</span>
                  <span>{v.sales.toLocaleString()} sales</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Coin System */}
        <CoinSystemBanner setPage={setPage} />

      </div>

      <Footer setPage={setPage} />
    </div>
  );
}

function SectionHeader({ title, action, onAction }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, fontWeight: 700 }}>{title}</h2>
      {action && (
        <button className="btn-ghost" onClick={onAction} style={{ padding: "6px 16px", borderRadius: 8, fontSize: 12 }}>
          {action} →
        </button>
      )}
    </div>
  );
}

function EscrowBanner() {
  return (
    <div style={{
      background: "linear-gradient(135deg, rgba(156,111,255,0.08), rgba(0,180,255,0.08))",
      border: "1px solid rgba(156,111,255,0.2)",
      borderRadius: 20, padding: "28px 32px",
      display: "flex", flexWrap: "wrap", gap: 24, alignItems: "center",
    }}>
      <div style={{ fontSize: 48 }}>🛡️</div>
      <div style={{ flex: 1, minWidth: 200 }}>
        <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, marginBottom: 8, color: T.purple }}>
          ESCROW PROTECTED TRANSACTIONS
        </h3>
        <p style={{ fontSize: 14, color: T.textMuted, lineHeight: 1.7, maxWidth: 580 }}>
          Payments are securely held in marketplace escrow until vendors successfully deliver the ordered products. Buyers may request refunds if products are not delivered as described.
        </p>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10, minWidth: 180 }}>
        {["Buyer pays with coins", "Coins held in escrow", "Item shipped & received", "Coins released to vendor"].map((step, i) => (
          <div key={step} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, color: T.textMuted }}>
            <div style={{
              width: 20, height: 20, borderRadius: "50%",
              background: "linear-gradient(135deg, #9C6FFF, #00B4FF)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 10, fontWeight: 700, color: "#fff", flexShrink: 0,
            }}>{i + 1}</div>
            {step}
          </div>
        ))}
      </div>
    </div>
  );
}

function CoinSystemBanner({ setPage }) {
  return (
    <div style={{
      background: "linear-gradient(135deg, #1A0F00, #2D1A00)",
      border: "1px solid rgba(255,140,0,0.2)",
      borderRadius: 20, padding: "28px 32px", marginBottom: 56,
      display: "flex", flexWrap: "wrap", gap: 24, alignItems: "center",
    }}>
      <div className="coin-float" style={{ fontSize: 52 }}>🪙</div>
      <div style={{ flex: 1, minWidth: 200 }}>
        <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, marginBottom: 8, color: T.gold }}>
          AUTOX COIN WALLET
        </h3>
        <p style={{ fontSize: 14, color: T.textMuted, lineHeight: 1.7, maxWidth: 500 }}>
          Top up your wallet using PayPal, credit card or debit card. Use AUTOX Coins to purchase parts instantly — no checkout friction, maximum security.
        </p>
        <div style={{ display: "flex", gap: 8, marginTop: 16, flexWrap: "wrap" }}>
          {["PayPal", "Visa", "Mastercard", "Amex"].map(m => (
            <span key={m} className="tag tag-gold">{m}</span>
          ))}
        </div>
      </div>
      <button className="btn-primary" onClick={() => setPage("wallet")} style={{ padding: "12px 28px", borderRadius: 12, fontSize: 14 }}>
        Top Up Coins →
      </button>
    </div>
  );
}

// ─── PAGE: MARKETPLACE ──────────────────────────────────────────────────────
function MarketplacePage({ setPage }) {
  const [activeType, setActiveType] = useState("all");
  const [sortBy, setSortBy] = useState("trending");
  const [priceRange, setPriceRange] = useState([0, 5000]);

  const filtered = PRODUCTS.filter(p => activeType === "all" || p.type === activeType);

  return (
    <div style={{ maxWidth: 1400, margin: "0 auto", padding: "32px 24px" }}>
      <div style={{ display: "flex", gap: 24 }}>
        {/* Sidebar Filters */}
        <div className="hide-mobile" style={{ width: 240, flexShrink: 0 }}>
          <div className="glass" style={{ borderRadius: 16, padding: 20, position: "sticky", top: 80 }}>
            <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 16, fontFamily: "'Orbitron', monospace" }}>FILTERS</h3>
            
            {/* Category */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 11, color: T.textMuted, fontWeight: 600, marginBottom: 10, letterSpacing: 0.5 }}>CATEGORY</div>
              {CATEGORIES.slice(0, 5).map(c => (
                <label key={c.id} style={{ display: "flex", alignItems: "center", gap: 8, padding: "4px 0", cursor: "pointer", fontSize: 13, color: T.textMuted }}>
                  <input type="checkbox" style={{ accentColor: T.gold }} /> {c.icon} {c.name}
                </label>
              ))}
            </div>

            {/* Condition */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 11, color: T.textMuted, fontWeight: 600, marginBottom: 10, letterSpacing: 0.5 }}>CONDITION</div>
              {["New", "Used - Excellent", "Used - Good"].map(c => (
                <label key={c} style={{ display: "flex", alignItems: "center", gap: 8, padding: "4px 0", cursor: "pointer", fontSize: 13, color: T.textMuted }}>
                  <input type="checkbox" style={{ accentColor: T.gold }} /> {c}
                </label>
              ))}
            </div>

            {/* Price */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 11, color: T.textMuted, fontWeight: 600, marginBottom: 10, letterSpacing: 0.5 }}>PRICE RANGE</div>
              <div style={{ fontSize: 13, color: T.gold, marginBottom: 8 }}>0 – 5,000 AXC</div>
              <input type="range" min="0" max="5000" style={{ width: "100%", accentColor: T.gold }} />
            </div>

            {/* Seller Rating */}
            <div>
              <div style={{ fontSize: 11, color: T.textMuted, fontWeight: 600, marginBottom: 10, letterSpacing: 0.5 }}>SELLER RATING</div>
              {["4.5+", "4.0+", "3.5+"].map(r => (
                <label key={r} style={{ display: "flex", alignItems: "center", gap: 8, padding: "4px 0", cursor: "pointer", fontSize: 13, color: T.textMuted }}>
                  <input type="radio" name="rating" style={{ accentColor: T.gold }} /> ⭐ {r}
                </label>
              ))}
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div style={{ flex: 1, minWidth: 0 }}>
          {/* Header */}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20, flexWrap: "wrap", gap: 12 }}>
            <h1 style={{ fontFamily: "'Orbitron', monospace", fontSize: 22 }}>Marketplace</h1>
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
              {[["all","All"], ["buy","Buy Now"], ["auction","Auction"], ["negotiable","Negotiate"]].map(([val, label]) => (
                <button key={val} className="nav-tab" onClick={() => setActiveType(val)}
                  style={{ fontSize: 12 }}
                  data-active={activeType === val}
                >
                  <span style={{
                    display: "inline-flex", alignItems: "center", padding: "6px 14px",
                    borderRadius: 8, background: activeType === val ? "rgba(255,140,0,0.15)" : "transparent",
                    color: activeType === val ? T.gold : T.textMuted,
                    border: activeType === val ? "1px solid rgba(255,140,0,0.3)" : "1px solid transparent",
                    fontSize: 12, cursor: "pointer", transition: "all 0.2s",
                  }}>{label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Sort + Results */}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
            <span style={{ fontSize: 13, color: T.textMuted }}>{filtered.length} results</span>
            <select value={sortBy} onChange={e => setSortBy(e.target.value)} style={{
              padding: "6px 12px", borderRadius: 8, fontSize: 12, cursor: "pointer",
            }}>
              <option value="trending">Trending</option>
              <option value="price_low">Price: Low to High</option>
              <option value="price_high">Price: High to Low</option>
              <option value="newest">Newest First</option>
              <option value="rating">Top Rated</option>
            </select>
          </div>

          <div className="grid-products">
            {filtered.map(p => <ProductCard key={p.id} product={p} setPage={setPage} />)}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── PAGE: PRODUCT DETAIL ───────────────────────────────────────────────────
function ProductPage({ setPage, walletBalance, setWalletBalance }) {
  const product = PRODUCTS[0];
  const [qty, setQty] = useState(1);
  const [offerAmount, setOfferAmount] = useState("");
  const [tab, setTab] = useState("details");
  const [purchased, setPurchased] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);

  const handleBuy = () => {
    if (walletBalance >= product.coins * qty) {
      setWalletBalance(prev => prev - product.coins * qty);
      setPurchased(true);
      setShowCheckout(false);
    } else {
      setPage("wallet");
    }
  };

  return (
    <div style={{ maxWidth: 1400, margin: "0 auto", padding: "32px 24px" }}>
      {purchased && (
        <div style={{
          background: "rgba(0,230,118,0.1)", border: "1px solid rgba(0,230,118,0.3)",
          borderRadius: 14, padding: "16px 24px", marginBottom: 24,
          display: "flex", alignItems: "center", gap: 12,
        }}>
          <span style={{ fontSize: 24 }}>✅</span>
          <div>
            <div style={{ fontWeight: 600, color: T.green }}>Order placed successfully!</div>
            <div style={{ fontSize: 13, color: T.textMuted }}>Coins held in escrow until delivery confirmed. Order #AX-{Math.floor(Math.random()*100000)}</div>
          </div>
        </div>
      )}

      <div style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
        {/* Images */}
        <div style={{ flex: "0 0 auto", width: "min(100%, 480px)" }}>
          <div style={{
            background: "linear-gradient(135deg, #1A0A00, #2D1400)",
            borderRadius: 20, height: 320, display: "flex", alignItems: "center",
            justifyContent: "center", fontSize: 100, marginBottom: 12,
            border: `1px solid ${T.border}`,
          }}>🔴</div>
          <div style={{ display: "flex", gap: 8 }}>
            {["🔴","🔴","🔴","🔴"].map((e, i) => (
              <div key={i} style={{
                flex: 1, height: 70, background: T.bgCard,
                borderRadius: 10, display: "flex", alignItems: "center",
                justifyContent: "center", fontSize: 24, cursor: "pointer",
                border: i === 0 ? `1px solid ${T.gold}` : `1px solid ${T.border}`,
              }}>{e}</div>
            ))}
          </div>
        </div>

        {/* Details */}
        <div style={{ flex: 1, minWidth: 280 }}>
          <div style={{ display: "flex", gap: 8, marginBottom: 12, flexWrap: "wrap" }}>
            <span className="tag tag-gold">Featured</span>
            <span className="tag tag-green">✓ Verified Part</span>
            <span className="tag tag-green">✓ Escrow</span>
          </div>
          <h1 style={{ fontFamily: "'Orbitron', monospace", fontSize: "clamp(18px, 3vw, 24px)", marginBottom: 8 }}>
            Brembo GT 6-Piston Brake Kit
          </h1>
          <div style={{ fontSize: 13, color: T.textMuted, marginBottom: 16 }}>
            🚗 Compatible: BMW M3 2019-2024 · Brand: Brembo · Condition: New
          </div>

          {/* Rating */}
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
            <span style={{ color: "#FFB347" }}>★★★★★</span>
            <span style={{ fontSize: 14, fontWeight: 600 }}>4.9</span>
            <span style={{ fontSize: 12, color: T.textMuted }}>234 reviews</span>
            <span style={{ fontSize: 12, color: T.green }}>98% positive</span>
          </div>

          {/* Price */}
          <div className="wallet-card" style={{ marginBottom: 20 }}>
            <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 28, fontWeight: 700, color: T.gold, marginBottom: 4 }}>
              2,800 AXC
            </div>
            <div style={{ fontSize: 13, color: T.textMuted }}>≈ $2,800 USD · Your balance: <span style={{ color: walletBalance >= 2800 ? T.green : T.red }}>{walletBalance.toLocaleString()} AXC</span></div>
          </div>

          {/* Qty */}
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
            <span style={{ fontSize: 13, color: T.textMuted }}>Quantity:</span>
            <div style={{ display: "flex", alignItems: "center", gap: 8, background: T.bgCard, borderRadius: 10, border: `1px solid ${T.border}`, padding: "6px 12px" }}>
              <button onClick={() => setQty(Math.max(1, qty-1))} style={{ background: "none", border: "none", color: T.gold, cursor: "pointer", fontSize: 16 }}>-</button>
              <span style={{ fontSize: 14, minWidth: 20, textAlign: "center" }}>{qty}</span>
              <button onClick={() => setQty(qty+1)} style={{ background: "none", border: "none", color: T.gold, cursor: "pointer", fontSize: 16 }}>+</button>
            </div>
            <span style={{ fontSize: 13, color: T.textMuted }}>12 in stock</span>
          </div>

          {/* CTA */}
          <div style={{ display: "flex", gap: 10, marginBottom: 16, flexWrap: "wrap" }}>
            <button className="btn-primary" onClick={() => setShowCheckout(true)} style={{
              flex: 1, minWidth: 140, padding: "13px 20px", borderRadius: 12, fontSize: 14,
            }}>
              🛒 Buy Now · {(2800 * qty).toLocaleString()} AXC
            </button>
            <button className="btn-ghost" style={{ padding: "13px 16px", borderRadius: 12, fontSize: 14 }}>
              🤍 Wishlist
            </button>
          </div>

          {/* Offer */}
          <div className="glass" style={{ borderRadius: 14, padding: 16, marginBottom: 16 }}>
            <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 10, color: T.blue }}>💬 Make an Offer</div>
            <div style={{ display: "flex", gap: 8 }}>
              <input value={offerAmount} onChange={e => setOfferAmount(e.target.value)}
                placeholder="Enter offer in AXC..." style={{ flex: 1, padding: "8px 12px", borderRadius: 8, fontSize: 13 }} />
              <button className="btn-ghost" style={{ padding: "8px 16px", borderRadius: 8, fontSize: 13, whiteSpace: "nowrap" }}>
                Send Offer
              </button>
            </div>
          </div>

          {/* Escrow notice */}
          <div className="escrow-badge">
            <div style={{ fontSize: 12, color: T.textMuted, lineHeight: 1.6 }}>
              🛡️ <strong style={{ color: T.purple }}>Escrow Protected</strong> — Your coins are securely held until you confirm delivery.
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ marginTop: 40 }}>
        <div style={{ display: "flex", gap: 4, borderBottom: `1px solid ${T.border}`, marginBottom: 24 }}>
          {["details","reviews","shipping","vendor"].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              background: "none", border: "none", cursor: "pointer",
              padding: "10px 20px", fontSize: 13, fontWeight: 500,
              color: tab === t ? T.gold : T.textMuted,
              borderBottom: tab === t ? `2px solid ${T.gold}` : "2px solid transparent",
              textTransform: "capitalize", fontFamily: "'DM Sans', sans-serif",
            }}>{t}</button>
          ))}
        </div>

        {tab === "details" && (
          <div style={{ fontSize: 14, color: T.textMuted, lineHeight: 1.8, maxWidth: 720 }}>
            <p>The Brembo GT 6-Piston Brake Kit represents the pinnacle of brake technology for performance street and track use. Featuring monoblock aluminum calipers, high-friction pads, and directionally-vented iron rotors, this system delivers consistent, fade-free stopping power under demanding conditions.</p>
            <br />
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
              {[["Caliper Type","6-Piston Monoblock"],["Rotor Diameter","380mm"],["Material","Aircraft-Grade Aluminum"],["Weight Savings","3.2 kg vs OEM"],["Finish","Gold Anodized"],["SKU","GT-BK-BMW-M3-19"]].map(([k,v]) => (
                <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "8px 12px", background: T.bgCard, borderRadius: 8, fontSize: 13 }}>
                  <span style={{ color: T.textMuted }}>{k}</span>
                  <span style={{ fontWeight: 600 }}>{v}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {tab === "reviews" && (
          <div style={{ maxWidth: 720 }}>
            {[{user:"BMW_M3_Owner", rating:5, comment:"Absolutely transformed the braking feel. Night and day difference from stock. Highly recommend.", date:"2 days ago"},
              {user:"TrackDay_Frank", rating:5, comment:"Used these on 3 track days so far. No fade, incredible feel. Worth every coin.", date:"1 week ago"},
              {user:"StreetSpec_M", rating:4, comment:"Great kit, installation was straightforward. Minor cosmetic issue on one caliper but functionally perfect.", date:"2 weeks ago"}
            ].map((r, i) => (
              <div key={i} style={{ borderBottom: `1px solid ${T.border}`, paddingBottom: 16, marginBottom: 16 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <div style={{ width: 32, height: 32, borderRadius: "50%", background: "linear-gradient(135deg, #FF8C00, #CC4400)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 700, color: "#000" }}>{r.user[0]}</div>
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{r.user}</span>
                  <span style={{ color: "#FFB347", fontSize: 12 }}>{"★".repeat(r.rating)}</span>
                  <span style={{ fontSize: 11, color: T.textMuted, marginLeft: "auto" }}>{r.date}</span>
                </div>
                <p style={{ fontSize: 13, color: T.textMuted, lineHeight: 1.6 }}>{r.comment}</p>
              </div>
            ))}
          </div>
        )}

        {tab === "shipping" && (
          <div style={{ maxWidth: 500, fontSize: 14, color: T.textMuted }}>
            {[["Standard Shipping","5-7 days","150 AXC"],["Express Shipping","2-3 days","280 AXC"],["Next Day","1 day","450 AXC"],["International","10-21 days","From 200 AXC"]].map(([m,t,p]) => (
              <div key={m} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 16px", background: T.bgCard, borderRadius: 10, marginBottom: 8 }}>
                <div><div style={{ fontWeight: 500, color: T.text }}>{m}</div><div style={{ fontSize: 12, marginTop: 2 }}>{t}</div></div>
                <span style={{ color: T.gold, fontWeight: 600 }}>{p}</span>
              </div>
            ))}
          </div>
        )}

        {tab === "vendor" && (
          <div style={{ display: "flex", gap: 20, flexWrap: "wrap" }}>
            <div className="glass" style={{ borderRadius: 16, padding: 24, minWidth: 240 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                <div style={{ width: 56, height: 56, borderRadius: 14, background: "linear-gradient(135deg, #FF8C00, #CC4400)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24 }}>🇺🇸</div>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 16 }}>ProBrake Co.</div>
                  <span className="tag tag-green">✓ Verified Vendor</span>
                </div>
              </div>
              {[["Rating","4.9 ⭐"],["Sales","12,400+"],["Response Time","< 2 hours"],["Member Since","2021"]].map(([k,v]) => (
                <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: `1px solid ${T.border}`, fontSize: 13 }}>
                  <span style={{ color: T.textMuted }}>{k}</span>
                  <span style={{ fontWeight: 600 }}>{v}</span>
                </div>
              ))}
              <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
                <button className="btn-primary" onClick={() => setPage("chat")} style={{ flex: 1, padding: "9px", borderRadius: 10, fontSize: 12 }}>💬 Message</button>
                <button className="btn-ghost" onClick={() => setPage("vendor")} style={{ flex: 1, padding: "9px", borderRadius: 10, fontSize: 12 }}>🏪 Shop</button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Checkout Modal */}
      {showCheckout && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 200,
          background: "rgba(0,0,0,0.8)", backdropFilter: "blur(8px)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: 24,
        }}>
          <div style={{
            background: T.bgCard, borderRadius: 24, padding: 32,
            maxWidth: 480, width: "100%", border: `1px solid ${T.border}`,
          }}>
            <h3 style={{ fontFamily: "'Orbitron', monospace", marginBottom: 20 }}>CONFIRM ORDER</h3>
            {[["Product","Brembo GT 6-Piston Kit"],["Quantity",qty],["Subtotal",`${(2800*qty).toLocaleString()} AXC`],["Shipping","150 AXC"],["Total",`${(2800*qty+150).toLocaleString()} AXC`]].map(([k,v]) => (
              <div key={k} style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: `1px solid ${T.border}`, fontSize: 14 }}>
                <span style={{ color: T.textMuted }}>{k}</span>
                <span style={{ fontWeight: k === "Total" ? 700 : 500, color: k === "Total" ? T.gold : T.text }}>{v}</span>
              </div>
            ))}
            <div className="escrow-badge" style={{ margin: "16px 0" }}>
              <div style={{ fontSize: 12, color: T.textMuted }}>🛡️ Coins will be held in escrow until delivery confirmed</div>
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <button className="btn-primary" onClick={handleBuy} style={{ flex: 1, padding: "13px", borderRadius: 12, fontSize: 14 }}>
                Confirm · {(2800*qty+150).toLocaleString()} AXC
              </button>
              <button className="btn-ghost" onClick={() => setShowCheckout(false)} style={{ padding: "13px 20px", borderRadius: 12, fontSize: 14 }}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── PAGE: WALLET ────────────────────────────────────────────────────────────
function WalletPage({ walletBalance, setWalletBalance }) {
  const [topUpAmount, setTopUpAmount] = useState("");
  const [payMethod, setPayMethod] = useState("paypal");
  const [processing, setProcessing] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleTopUp = () => {
    const amt = parseInt(topUpAmount);
    if (!amt || amt < 10) return;
    setProcessing(true);
    setTimeout(() => {
      setWalletBalance(prev => prev + amt);
      setProcessing(false);
      setSuccess(true);
      setTopUpAmount("");
      setTimeout(() => setSuccess(false), 4000);
    }, 2000);
  };

  const txHistory = [
    { type: "topup", desc: "PayPal Top-Up", amount: "+1000 AXC", date: "May 24", color: T.green },
    { type: "purchase", desc: "BC Racing Coilovers", amount: "-1200 AXC", date: "May 22", color: T.red },
    { type: "topup", desc: "Card Top-Up", amount: "+2000 AXC", date: "May 20", color: T.green },
    { type: "escrow", desc: "Escrow Released", amount: "+850 AXC", date: "May 18", color: T.purple },
    { type: "purchase", desc: "Turbosmart BOV", amount: "-320 AXC", date: "May 15", color: T.red },
  ];

  return (
    <div style={{ maxWidth: 1000, margin: "0 auto", padding: "32px 24px" }}>
      <h1 style={{ fontFamily: "'Orbitron', monospace", fontSize: 22, marginBottom: 32 }}>MY WALLET</h1>

      {success && (
        <div style={{
          background: "rgba(0,230,118,0.1)", border: "1px solid rgba(0,230,118,0.3)",
          borderRadius: 12, padding: "14px 20px", marginBottom: 24, fontSize: 14, color: T.green,
        }}>✅ Coins added successfully! Your balance has been updated.</div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 20, marginBottom: 32 }}>
        {/* Balance Cards */}
        <div className="wallet-card">
          <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 4, letterSpacing: 1 }}>AVAILABLE BALANCE</div>
          <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 32, fontWeight: 700, color: T.gold }} className="coin-float">
            {walletBalance.toLocaleString()}
          </div>
          <div style={{ fontSize: 14, color: T.textMuted }}>AUTOX Coins · ≈ ${walletBalance.toLocaleString()} USD</div>
        </div>
        <div style={{ background: "linear-gradient(135deg, rgba(156,111,255,0.1), rgba(0,180,255,0.1))", border: "1px solid rgba(156,111,255,0.3)", borderRadius: 20, padding: 28 }}>
          <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 4, letterSpacing: 1 }}>IN ESCROW</div>
          <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 32, fontWeight: 700, color: T.purple }}>2,800</div>
          <div style={{ fontSize: 14, color: T.textMuted }}>Awaiting delivery confirmation</div>
        </div>
        <div style={{ background: "linear-gradient(135deg, rgba(0,230,118,0.08), rgba(0,180,255,0.05))", border: "1px solid rgba(0,230,118,0.2)", borderRadius: 20, padding: 28 }}>
          <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 4, letterSpacing: 1 }}>TOTAL SPENT</div>
          <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 32, fontWeight: 700, color: T.green }}>14,200</div>
          <div style={{ fontSize: 14, color: T.textMuted }}>Lifetime purchase total</div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))", gap: 24 }}>
        {/* Top Up */}
        <div className="glass" style={{ borderRadius: 20, padding: 28 }}>
          <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 16, marginBottom: 20 }}>TOP UP COINS</h3>

          {/* Quick amounts */}
          <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 10, fontWeight: 600 }}>QUICK SELECT</div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 16 }}>
            {[500, 1000, 2500, 5000].map(amt => (
              <button key={amt} onClick={() => setTopUpAmount(String(amt))} className="btn-ghost" style={{
                padding: "10px", borderRadius: 10, fontSize: 13,
                borderColor: topUpAmount === String(amt) ? T.gold : undefined,
                color: topUpAmount === String(amt) ? T.gold : undefined,
              }}>
                {amt.toLocaleString()} AXC<br />
                <span style={{ fontSize: 10, color: T.textMuted }}>${amt}</span>
              </button>
            ))}
          </div>

          <input value={topUpAmount} onChange={e => setTopUpAmount(e.target.value)}
            placeholder="Custom amount (min. 10 AXC)" style={{
              width: "100%", padding: "10px 14px", borderRadius: 10, fontSize: 14, marginBottom: 16,
            }} />

          {/* Payment Method */}
          <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 10, fontWeight: 600 }}>PAYMENT METHOD</div>
          <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 20 }}>
            {[
              { id: "paypal", label: "PayPal Balance", icon: "🅿️" },
              { id: "card", label: "Credit / Debit Card via PayPal", icon: "💳" },
            ].map(m => (
              <label key={m.id} style={{
                display: "flex", alignItems: "center", gap: 10,
                padding: "12px 14px", borderRadius: 10, cursor: "pointer",
                background: payMethod === m.id ? "rgba(255,140,0,0.08)" : T.bgCard,
                border: `1px solid ${payMethod === m.id ? "rgba(255,140,0,0.4)" : T.border}`,
              }}>
                <input type="radio" name="payMethod" value={m.id} checked={payMethod === m.id}
                  onChange={() => setPayMethod(m.id)} style={{ accentColor: T.gold }} />
                <span style={{ fontSize: 18 }}>{m.icon}</span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{m.label}</div>
                  <div style={{ fontSize: 10, color: T.textMuted }}>Powered by PayPal Advanced Checkout</div>
                </div>
              </label>
            ))}
          </div>

          <div style={{ fontSize: 11, color: T.textMuted, marginBottom: 16, padding: "10px 14px", background: "rgba(255,140,0,0.05)", borderRadius: 8, border: "1px solid rgba(255,140,0,0.15)" }}>
            💡 1 AXC = $1.00 USD · Instant credit · Secure PayPal checkout
          </div>

          <button className="btn-primary" onClick={handleTopUp} disabled={processing} style={{
            width: "100%", padding: "14px", borderRadius: 12, fontSize: 14,
            opacity: processing ? 0.7 : 1,
          }}>
            {processing ? (
              <span style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                <span style={{ width: 16, height: 16, border: "2px solid #000", borderTopColor: "transparent", borderRadius: "50%", display: "inline-block", animation: "spin 0.8s linear infinite" }} />
                Processing PayPal...
              </span>
            ) : `Top Up ${topUpAmount ? parseInt(topUpAmount).toLocaleString() : ""} AXC`}
          </button>
        </div>

        {/* Transaction History */}
        <div className="glass" style={{ borderRadius: 20, padding: 28 }}>
          <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 16, marginBottom: 20 }}>TRANSACTION HISTORY</h3>
          {txHistory.map((tx, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 12, padding: "12px 0",
              borderBottom: i < txHistory.length - 1 ? `1px solid ${T.border}` : "none",
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                background: tx.type === "topup" ? "rgba(0,230,118,0.1)" : tx.type === "escrow" ? "rgba(156,111,255,0.1)" : "rgba(255,59,59,0.1)",
                display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16,
              }}>
                {tx.type === "topup" ? "⬆️" : tx.type === "escrow" ? "🛡️" : "🛒"}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{tx.desc}</div>
                <div style={{ fontSize: 11, color: T.textMuted }}>{tx.date}</div>
              </div>
              <div style={{ fontSize: 14, fontWeight: 700, color: tx.color }}>{tx.amount}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── PAGE: DASHBOARD ─────────────────────────────────────────────────────────
function DashboardPage({ setPage, walletBalance }) {
  const [activeSection, setActiveSection] = useState("overview");

  const sidebarItems = [
    { id: "overview", icon: "📊", label: "Overview" },
    { id: "orders", icon: "📦", label: "Orders" },
    { id: "escrow", icon: "🛡️", label: "Escrow Orders" },
    { id: "bids", icon: "🔨", label: "My Bids" },
    { id: "offers", icon: "💬", label: "Offers" },
    { id: "wishlist", icon: "❤️", label: "Wishlist" },
    { id: "messages", icon: "✉️", label: "Messages" },
    { id: "notifications", icon: "🔔", label: "Notifications" },
    { id: "addresses", icon: "📍", label: "Addresses" },
    { id: "settings", icon: "⚙️", label: "Settings" },
  ];

  return (
    <div style={{ maxWidth: 1400, margin: "0 auto", padding: "32px 24px", display: "flex", gap: 24, flexWrap: "wrap" }}>
      {/* Sidebar */}
      <div style={{ width: 220, flexShrink: 0 }}>
        {/* Profile card */}
        <div className="glass" style={{ borderRadius: 16, padding: 20, marginBottom: 16, textAlign: "center" }}>
          <div style={{
            width: 60, height: 60, borderRadius: "50%",
            background: "linear-gradient(135deg, #FF8C00, #CC4400)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 22, fontWeight: 700, color: "#000", margin: "0 auto 12px",
          }}>JD</div>
          <div style={{ fontWeight: 600, marginBottom: 2 }}>John Driver</div>
          <div style={{ fontSize: 12, color: T.textMuted }}>john@example.com</div>
          <div style={{ marginTop: 8 }}><span className="tag tag-blue">Buyer</span></div>
          <div style={{ marginTop: 12, padding: "8px 12px", background: "rgba(255,140,0,0.08)", borderRadius: 10 }}>
            <div style={{ fontSize: 11, color: T.textMuted }}>Balance</div>
            <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 16, color: T.gold, fontWeight: 700 }}>
              {walletBalance.toLocaleString()} AXC
            </div>
          </div>
        </div>
        <div className="glass" style={{ borderRadius: 16, padding: 10 }}>
          {sidebarItems.map(item => (
            <div key={item.id} className={`sidebar-link ${activeSection === item.id ? "active" : ""}`}
              onClick={() => setActiveSection(item.id)}>
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Main */}
      <div style={{ flex: 1, minWidth: 0 }}>
        {activeSection === "overview" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>DASHBOARD</h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 14, marginBottom: 28 }}>
              {[
                { label: "Total Orders", value: "24", icon: "📦", color: T.blue },
                { label: "In Escrow", value: "2,800 AXC", icon: "🛡️", color: T.purple },
                { label: "Active Bids", value: "3", icon: "🔨", color: T.red },
                { label: "Wishlist", value: "12", icon: "❤️", color: T.gold },
              ].map(s => (
                <div key={s.label} style={{ background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 14, padding: 18 }}>
                  <div style={{ fontSize: 24, marginBottom: 8 }}>{s.icon}</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: s.color, fontFamily: "'Orbitron', monospace" }}>{s.value}</div>
                  <div style={{ fontSize: 11, color: T.textMuted, marginTop: 4 }}>{s.label}</div>
                </div>
              ))}
            </div>

            <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 14, fontFamily: "'Orbitron', monospace" }}>RECENT ORDERS</h3>
            {[
              { id: "AX-84721", product: "BC Racing Coilover Kit", status: "In Escrow", coins: 1200, date: "May 22" },
              { id: "AX-84650", product: "Turbosmart BOV Kompact", status: "Delivered", coins: 320, date: "May 15" },
              { id: "AX-84431", product: "HID Motorsports Xenon Kit", status: "Delivered", coins: 189, date: "May 8" },
            ].map(order => (
              <div key={order.id} style={{
                display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap",
                background: T.bgCard, border: `1px solid ${T.border}`,
                borderRadius: 12, padding: "14px 16px", marginBottom: 10,
              }}>
                <div style={{ flex: 1, minWidth: 150 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{order.product}</div>
                  <div style={{ fontSize: 11, color: T.textMuted }}>{order.id} · {order.date}</div>
                </div>
                <span className={`tag ${order.status === "In Escrow" ? "tag-purple" : "tag-green"}`}>{order.status}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: T.gold }}>{order.coins.toLocaleString()} AXC</span>
              </div>
            ))}
          </div>
        )}

        {activeSection === "orders" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>MY ORDERS</h2>
            {[
              { id: "AX-84721", product: "BC Racing Coilover Kit", status: "In Escrow", coins: 1200, vendor: "Track Ready", date: "May 22" },
              { id: "AX-84650", product: "Turbosmart BOV Kompact", status: "Shipped", coins: 320, vendor: "Boost Kings", date: "May 15" },
              { id: "AX-84431", product: "HID Motorsports Xenon Kit", status: "Delivered", coins: 189, vendor: "LuxLight", date: "May 8" },
              { id: "AX-84210", product: "Recaro Pole Position Seat", status: "Delivered", coins: 1800, vendor: "Race Seats EU", date: "Apr 28" },
            ].map(order => (
              <div key={order.id} className="card-hover" style={{
                background: T.bgCard, border: `1px solid ${T.border}`,
                borderRadius: 14, padding: 20, marginBottom: 12,
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 10 }}>
                  <div>
                    <div style={{ fontWeight: 600, marginBottom: 4 }}>{order.product}</div>
                    <div style={{ fontSize: 12, color: T.textMuted }}>Order {order.id} · Vendor: {order.vendor} · {order.date}</div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <span className={`tag ${order.status === "In Escrow" ? "tag-purple" : order.status === "Shipped" ? "tag-blue" : "tag-green"}`}>{order.status}</span>
                    <div style={{ fontSize: 16, fontWeight: 700, color: T.gold, marginTop: 4 }}>{order.coins.toLocaleString()} AXC</div>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
                  {order.status === "In Escrow" && <button className="btn-primary" style={{ padding: "7px 16px", borderRadius: 8, fontSize: 12 }}>Confirm Delivery</button>}
                  {order.status === "Delivered" && <button className="btn-ghost" style={{ padding: "7px 16px", borderRadius: 8, fontSize: 12 }}>Re-order</button>}
                  <button className="btn-ghost" style={{ padding: "7px 16px", borderRadius: 8, fontSize: 12 }}>Track Order</button>
                  <button className="btn-ghost" style={{ padding: "7px 16px", borderRadius: 8, fontSize: 12 }}>Request Refund</button>
                </div>
              </div>
            ))}
          </div>
        )}

        {activeSection === "messages" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>MESSAGES</h2>
            {[
              { vendor: "JDM Direct", last: "Thanks for your order! Shipping tomorrow.", time: "2h ago", unread: 1 },
              { vendor: "EU Performance", last: "Your offer of 3400 AXC has been accepted!", time: "5h ago", unread: 2 },
              { vendor: "Track Ready", last: "Package dispatched, tracking: UK123456", time: "1d ago", unread: 0 },
            ].map((msg, i) => (
              <div key={i} onClick={() => setPage("chat")} className="card-hover" style={{
                background: T.bgCard, border: `1px solid ${T.border}`,
                borderRadius: 14, padding: 16, marginBottom: 10, cursor: "pointer",
                display: "flex", gap: 14, alignItems: "center",
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12, flexShrink: 0,
                  background: "linear-gradient(135deg, #FF8C00, #CC4400)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 16, fontWeight: 700, color: "#000",
                }}>{msg.vendor[0]}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{msg.vendor}</div>
                  <div style={{ fontSize: 12, color: T.textMuted, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{msg.last}</div>
                </div>
                <div style={{ textAlign: "right", flexShrink: 0 }}>
                  <div style={{ fontSize: 11, color: T.textMuted }}>{msg.time}</div>
                  {msg.unread > 0 && (
                    <div style={{ marginTop: 4, background: T.gold, color: "#000", width: 18, height: 18, borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 700, marginLeft: "auto" }}>{msg.unread}</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {!["overview", "orders", "messages"].includes(activeSection) && (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>
              {sidebarItems.find(s => s.id === activeSection)?.icon}
            </div>
            <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, marginBottom: 8 }}>
              {sidebarItems.find(s => s.id === activeSection)?.label}
            </h3>
            <p style={{ color: T.textMuted, fontSize: 14 }}>This section is fully built in the production app.</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── PAGE: CHAT ──────────────────────────────────────────────────────────────
function ChatPage() {
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState([
    { from: "vendor", text: "Hi! Thanks for your interest in the Brembo kit. It's brand new, just arrived from Italy.", time: "10:32" },
    { from: "me", text: "Great! Can you do 2600 AXC? I'm buying two kits.", time: "10:34" },
    { from: "vendor", text: "For two kits I can do 2650 AXC each. That's my best offer. Free shipping included.", time: "10:35" },
    { from: "me", text: "Deal! I'll place the order now.", time: "10:36" },
    { from: "vendor", text: "Perfect! I'll have it shipped within 24 hours. 🚀", time: "10:36" },
  ]);

  const sendMessage = () => {
    if (!message.trim()) return;
    setMessages(prev => [...prev, { from: "me", text: message, time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) }]);
    setMessage("");
  };

  return (
    <div style={{ maxWidth: 800, margin: "0 auto", padding: "32px 24px" }}>
      <div className="glass" style={{ borderRadius: 20, overflow: "hidden" }}>
        {/* Header */}
        <div style={{ padding: "16px 20px", borderBottom: `1px solid ${T.border}`, display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, background: "linear-gradient(135deg, #FF8C00, #CC4400)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, fontWeight: 700, color: "#000" }}>P</div>
          <div>
            <div style={{ fontWeight: 600 }}>ProBrake Co.</div>
            <div style={{ fontSize: 11, color: T.green }}>● Online · Verified Vendor</div>
          </div>
          <div style={{ marginLeft: "auto", display: "flex", gap: 8 }}>
            <span className="tag tag-green">✓ Verified</span>
            <span className="tag tag-gold">4.9 ⭐</span>
          </div>
        </div>

        {/* Messages */}
        <div style={{ padding: 20, minHeight: 360, maxHeight: 400, overflowY: "auto", display: "flex", flexDirection: "column", gap: 10 }}>
          {messages.map((m, i) => (
            <div key={i} style={{ display: "flex", justifyContent: m.from === "me" ? "flex-end" : "flex-start" }}>
              <div style={{
                maxWidth: "70%", padding: "10px 14px", borderRadius: 14,
                background: m.from === "me" ? "linear-gradient(135deg, #FF8C00, #CC4400)" : T.bgCard,
                color: m.from === "me" ? "#000" : T.text,
                border: m.from === "me" ? "none" : `1px solid ${T.border}`,
                fontSize: 13, lineHeight: 1.5,
              }}>
                <div>{m.text}</div>
                <div style={{ fontSize: 10, opacity: 0.6, marginTop: 4, textAlign: "right" }}>{m.time}</div>
              </div>
            </div>
          ))}
          <div style={{ fontSize: 11, color: T.textMuted, textAlign: "center", fontStyle: "italic" }}>
            <span style={{ animation: "blink 1s infinite" }}>●</span> ProBrake Co. is typing...
          </div>
        </div>

        {/* Input */}
        <div style={{ padding: "14px 20px", borderTop: `1px solid ${T.border}`, display: "flex", gap: 10 }}>
          <input value={message} onChange={e => setMessage(e.target.value)}
            onKeyDown={e => e.key === "Enter" && sendMessage()}
            placeholder="Type a message..." style={{
              flex: 1, padding: "10px 14px", borderRadius: 10, fontSize: 13,
            }} />
          <button className="btn-ghost" style={{ padding: "10px 14px", borderRadius: 10, fontSize: 16 }}>📎</button>
          <button className="btn-primary" onClick={sendMessage} style={{ padding: "10px 18px", borderRadius: 10, fontSize: 13 }}>Send →</button>
        </div>
      </div>
    </div>
  );
}

// ─── PAGE: AUCTIONS ──────────────────────────────────────────────────────────
function AuctionsPage({ setPage }) {
  const auctions = PRODUCTS.filter(p => p.type === "auction");
  const [bidAmount, setBidAmount] = useState("");
  const [selectedAuction, setSelectedAuction] = useState(null);

  return (
    <div style={{ maxWidth: 1400, margin: "0 auto", padding: "32px 24px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontFamily: "'Orbitron', monospace", fontSize: 22 }}>LIVE AUCTIONS</h1>
        <span className="tag tag-red" style={{ animation: "pulse 1s infinite" }}>● LIVE</span>
        <span style={{ fontSize: 13, color: T.textMuted }}>1,247 active auctions</span>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 20 }}>
        {[...auctions, ...auctions].map((a, i) => (
          <div key={i} className="card-hover" style={{
            background: T.bgCard, border: `1px solid ${T.border}`,
            borderRadius: 18, overflow: "hidden",
          }}>
            <div style={{
              height: 140, background: "linear-gradient(135deg, #1A0A00, #0F1F3D)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 60, position: "relative",
            }}>
              {a.img}
              <div style={{ position: "absolute", top: 10, right: 10 }}>
                <span className="auction-timer">⏱ {a.timeLeft || "1h 30m"}</span>
              </div>
            </div>
            <div style={{ padding: 16 }}>
              <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 4 }}>{a.brand} · {a.compatible}</div>
              <div style={{ fontWeight: 600, marginBottom: 10 }}>{a.title}</div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <div>
                  <div style={{ fontSize: 11, color: T.textMuted }}>Current Bid</div>
                  <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, color: T.gold, fontWeight: 700 }}>
                    {(a.coins + (i * 120)).toLocaleString()} AXC
                  </div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ fontSize: 11, color: T.textMuted }}>{a.bids + i} bids</div>
                  <div style={{ fontSize: 11, color: T.green }}>You're {i % 2 === 0 ? "winning" : "outbid"}</div>
                </div>
              </div>

              {/* Bid progress */}
              <div style={{ marginBottom: 12 }}>
                <div className="progress-bar">
                  <div className="progress-fill" style={{ width: `${60 + i * 10}%` }} />
                </div>
                <div style={{ fontSize: 10, color: T.textMuted, marginTop: 4 }}>{60 + i * 10}% of reserve met</div>
              </div>

              <div style={{ display: "flex", gap: 8 }}>
                <input placeholder={`Min ${(a.coins + (i * 120) + 50).toLocaleString()} AXC`} style={{
                  flex: 1, padding: "8px 12px", borderRadius: 8, fontSize: 12,
                }} />
                <button className="btn-primary" onClick={() => setPage("product")} style={{
                  padding: "8px 16px", borderRadius: 8, fontSize: 12,
                }}>Bid Now</button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── PAGE: ADMIN ──────────────────────────────────────────────────────────────
function AdminPage() {
  const [section, setSection] = useState("overview");

  const adminSidebar = [
    { id: "overview", icon: "📊", label: "Dashboard" },
    { id: "users", icon: "👥", label: "User Management" },
    { id: "vendors", icon: "🏪", label: "Vendor Approvals" },
    { id: "listings", icon: "📦", label: "Listings" },
    { id: "escrow", icon: "🛡️", label: "Escrow Manager" },
    { id: "refunds", icon: "↩️", label: "Refund Requests" },
    { id: "coins", icon: "🪙", label: "Coin Controls" },
    { id: "disputes", icon: "⚖️", label: "Disputes" },
    { id: "analytics", icon: "📈", label: "Analytics" },
    { id: "revenue", icon: "💰", label: "Revenue" },
    { id: "fraud", icon: "🚨", label: "Fraud Monitor" },
    { id: "kyc", icon: "🪪", label: "KYC Verification" },
    { id: "paypal", icon: "🅿️", label: "PayPal Settings" },
    { id: "fees", icon: "💲", label: "Fee Settings" },
    { id: "cms", icon: "📝", label: "CMS Pages" },
  ];

  return (
    <div style={{ display: "flex", minHeight: "calc(100vh - 64px)" }}>
      {/* Admin Sidebar */}
      <div style={{
        width: 220, flexShrink: 0, background: "#060A12",
        borderRight: `1px solid ${T.border}`, padding: "20px 12px",
        position: "sticky", top: 64, height: "calc(100vh - 64px)", overflowY: "auto",
      }}>
        <div style={{ fontSize: 10, color: T.gold, fontWeight: 700, letterSpacing: 1.5, marginBottom: 16, padding: "0 4px" }}>ADMIN PANEL</div>
        {adminSidebar.map(item => (
          <div key={item.id} className={`sidebar-link ${section === item.id ? "active" : ""}`}
            onClick={() => setSection(item.id)}>
            <span>{item.icon}</span>
            <span style={{ fontSize: 12 }}>{item.label}</span>
          </div>
        ))}
      </div>

      {/* Admin Content */}
      <div style={{ flex: 1, padding: "28px 28px", overflowY: "auto" }}>
        {section === "overview" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>ADMIN DASHBOARD</h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 14, marginBottom: 28 }}>
              {[
                { label: "Total Revenue", value: "$1.24M", icon: "💰", color: T.gold },
                { label: "Platform Fees", value: "$42K", icon: "💲", color: T.green },
                { label: "In Escrow", value: "$284K", icon: "🛡️", color: T.purple },
                { label: "Active Users", value: "89,240", icon: "👥", color: T.blue },
                { label: "Pending KYC", value: "124", icon: "🪪", color: T.gold },
                { label: "Open Disputes", value: "18", icon: "⚖️", color: T.red },
              ].map(s => (
                <div key={s.label} style={{ background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 14, padding: 16 }}>
                  <div style={{ fontSize: 22, marginBottom: 8 }}>{s.icon}</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: s.color, fontFamily: "'Orbitron', monospace" }}>{s.value}</div>
                  <div style={{ fontSize: 11, color: T.textMuted, marginTop: 4 }}>{s.label}</div>
                </div>
              ))}
            </div>

            {/* Recent activity */}
            <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 14, fontFamily: "'Orbitron', monospace" }}>RECENT ACTIVITY</h3>
            {[
              { action: "New Vendor Registration", user: "speedparts_uk", time: "2m ago", type: "vendor" },
              { action: "Dispute Opened", user: "buyer_92841", time: "8m ago", type: "dispute" },
              { action: "KYC Submitted", user: "jdm_shop_osaka", time: "15m ago", type: "kyc" },
              { action: "Large Escrow Release", user: "eu_perf_gmbh", time: "22m ago", type: "escrow" },
              { action: "Fraud Alert Triggered", user: "unknown_user", time: "1h ago", type: "fraud" },
            ].map((a, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 12, padding: "11px 14px",
                background: T.bgCard, borderRadius: 10, marginBottom: 8, border: `1px solid ${T.border}`,
              }}>
                <div style={{ fontSize: 18 }}>
                  {a.type === "vendor" ? "🏪" : a.type === "dispute" ? "⚖️" : a.type === "kyc" ? "🪪" : a.type === "escrow" ? "🛡️" : "🚨"}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{a.action}</div>
                  <div style={{ fontSize: 11, color: T.textMuted }}>@{a.user}</div>
                </div>
                <div style={{ fontSize: 11, color: T.textMuted }}>{a.time}</div>
                <button className="btn-ghost" style={{ padding: "4px 12px", borderRadius: 6, fontSize: 11 }}>Review</button>
              </div>
            ))}
          </div>
        )}

        {section === "coins" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>COIN CONTROLS</h2>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
              {[
                { label: "AXC to USD Rate", value: "1.00", unit: "USD" },
                { label: "Platform Fee", value: "3.5", unit: "%" },
                { label: "Withdrawal Fee", value: "1.5", unit: "%" },
                { label: "Min Top-Up", value: "10", unit: "AXC" },
                { label: "Max Top-Up Daily", value: "50000", unit: "AXC" },
                { label: "Withdrawal Cooldown", value: "24", unit: "hours" },
              ].map(field => (
                <div key={field.label} style={{ background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 14, padding: 16 }}>
                  <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 8 }}>{field.label}</div>
                  <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                    <input defaultValue={field.value} style={{ flex: 1, padding: "8px 12px", borderRadius: 8, fontSize: 14 }} />
                    <span style={{ fontSize: 12, color: T.gold, fontWeight: 600 }}>{field.unit}</span>
                  </div>
                </div>
              ))}
            </div>
            <button className="btn-primary" style={{ marginTop: 20, padding: "12px 28px", borderRadius: 12, fontSize: 13 }}>Save Settings</button>
          </div>
        )}

        {!["overview", "coins"].includes(section) && (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>
              {adminSidebar.find(s => s.id === section)?.icon}
            </div>
            <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, marginBottom: 8 }}>
              {adminSidebar.find(s => s.id === section)?.label.toUpperCase()}
            </h3>
            <p style={{ color: T.textMuted, fontSize: 14 }}>Full module implemented in production build.</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── PAGE: VENDOR ─────────────────────────────────────────────────────────────
function VendorPage({ setPage }) {
  const [section, setSection] = useState("overview");

  const vendorSidebar = [
    { id: "overview", icon: "📊", label: "Dashboard" },
    { id: "products", icon: "📦", label: "Products" },
    { id: "add", icon: "➕", label: "Add Listing" },
    { id: "orders", icon: "🛒", label: "Orders" },
    { id: "escrow", icon: "🛡️", label: "Escrow Earnings" },
    { id: "payouts", icon: "💸", label: "Pending Payouts" },
    { id: "offers", icon: "💬", label: "Offer Management" },
    { id: "bids", icon: "🔨", label: "Auction Bids" },
    { id: "analytics", icon: "📈", label: "Analytics" },
    { id: "messages", icon: "✉️", label: "Messages" },
    { id: "shop", icon: "🏪", label: "Shop Settings" },
  ];

  return (
    <div style={{ display: "flex", minHeight: "calc(100vh - 64px)" }}>
      <div style={{
        width: 210, flexShrink: 0, background: "#060A12",
        borderRight: `1px solid ${T.border}`, padding: "20px 12px",
        position: "sticky", top: 64, height: "calc(100vh - 64px)", overflowY: "auto",
      }}>
        <div style={{ padding: "0 4px 16px", borderBottom: `1px solid ${T.border}`, marginBottom: 16 }}>
          <div style={{ fontWeight: 700, fontSize: 14 }}>JDM Direct</div>
          <div style={{ fontSize: 11, color: T.green }}>✓ Verified Vendor</div>
          <div style={{ fontSize: 12, color: T.textMuted, marginTop: 4 }}>🪙 12,400 AXC balance</div>
        </div>
        {vendorSidebar.map(item => (
          <div key={item.id} className={`sidebar-link ${section === item.id ? "active" : ""}`}
            onClick={() => setSection(item.id)}>
            <span>{item.icon}</span>
            <span style={{ fontSize: 12 }}>{item.label}</span>
          </div>
        ))}
      </div>

      <div style={{ flex: 1, padding: "28px", overflowY: "auto" }}>
        {section === "overview" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>VENDOR DASHBOARD</h2>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 14, marginBottom: 28 }}>
              {[
                { label: "Total Sales", value: "142K AXC", icon: "💰", color: T.gold },
                { label: "In Escrow", value: "8,400 AXC", icon: "🛡️", color: T.purple },
                { label: "Active Listings", value: "48", icon: "📦", color: T.blue },
                { label: "Pending Orders", value: "7", icon: "🚀", color: T.green },
                { label: "Avg Rating", value: "4.9 ⭐", icon: "🌟", color: T.gold },
                { label: "Open Offers", value: "12", icon: "💬", color: T.blue },
              ].map(s => (
                <div key={s.label} style={{ background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 14, padding: 16 }}>
                  <div style={{ fontSize: 22, marginBottom: 8 }}>{s.icon}</div>
                  <div style={{ fontSize: 16, fontWeight: 700, color: s.color, fontFamily: "'Orbitron', monospace" }}>{s.value}</div>
                  <div style={{ fontSize: 11, color: T.textMuted, marginTop: 4 }}>{s.label}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {section === "add" && (
          <div>
            <h2 style={{ fontFamily: "'Orbitron', monospace", fontSize: 20, marginBottom: 24 }}>ADD NEW LISTING</h2>
            <div className="glass" style={{ borderRadius: 20, padding: 28 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
                {[
                  { label: "Product Title", placeholder: "e.g. Brembo GT 6-Piston Brake Kit" },
                  { label: "Brand", placeholder: "e.g. Brembo" },
                  { label: "SKU", placeholder: "e.g. BRM-GT-001" },
                  { label: "Price (AXC)", placeholder: "e.g. 2800" },
                  { label: "Quantity", placeholder: "e.g. 5" },
                  { label: "Vehicle Make", placeholder: "e.g. BMW" },
                  { label: "Vehicle Model", placeholder: "e.g. M3" },
                  { label: "Vehicle Year", placeholder: "e.g. 2020-2024" },
                ].map(f => (
                  <div key={f.label}>
                    <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 6, fontWeight: 500 }}>{f.label}</div>
                    <input placeholder={f.placeholder} style={{ width: "100%", padding: "9px 12px", borderRadius: 8, fontSize: 13 }} />
                  </div>
                ))}
              </div>

              <div style={{ marginTop: 16 }}>
                <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 6 }}>Category</div>
                <select style={{ width: "100%", padding: "9px 12px", borderRadius: 8, fontSize: 13, cursor: "pointer" }}>
                  {CATEGORIES.map(c => <option key={c.id}>{c.icon} {c.name}</option>)}
                </select>
              </div>

              <div style={{ marginTop: 16 }}>
                <div style={{ fontSize: 12, color: T.textMuted, marginBottom: 6 }}>Description</div>
                <textarea placeholder="Detailed product description..." style={{
                  width: "100%", padding: "10px 12px", borderRadius: 8, fontSize: 13,
                  background: "rgba(255,255,255,0.04)", border: `1px solid rgba(255,255,255,0.1)`,
                  color: T.text, resize: "vertical", minHeight: 100,
                  fontFamily: "'DM Sans', sans-serif",
                }} />
              </div>

              <div style={{ display: "flex", gap: 20, marginTop: 16 }}>
                {[
                  { label: "Negotiable", id: "neg" },
                  { label: "Auction / Bidding", id: "auc" },
                  { label: "Featured Listing", id: "feat" },
                ].map(opt => (
                  <label key={opt.id} style={{ display: "flex", alignItems: "center", gap: 6, cursor: "pointer", fontSize: 13 }}>
                    <input type="checkbox" style={{ accentColor: T.gold }} /> {opt.label}
                  </label>
                ))}
              </div>

              <div style={{ marginTop: 16, border: `2px dashed rgba(255,255,255,0.1)`, borderRadius: 12, padding: "28px", textAlign: "center", cursor: "pointer" }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>📸</div>
                <div style={{ fontSize: 13, color: T.textMuted }}>Drag & drop product images or click to upload</div>
                <div style={{ fontSize: 11, color: T.textDim, marginTop: 4 }}>JPG, PNG, WebP · Max 10MB · Up to 8 images</div>
              </div>

              <button className="btn-primary" style={{ width: "100%", marginTop: 20, padding: "14px", borderRadius: 12, fontSize: 14 }}>
                Publish Listing
              </button>
            </div>
          </div>
        )}

        {!["overview", "add"].includes(section) && (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>{vendorSidebar.find(s => s.id === section)?.icon}</div>
            <h3 style={{ fontFamily: "'Orbitron', monospace", fontSize: 18, marginBottom: 8 }}>
              {vendorSidebar.find(s => s.id === section)?.label.toUpperCase()}
            </h3>
            <p style={{ color: T.textMuted, fontSize: 14 }}>Full module implemented in production build.</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── FOOTER ───────────────────────────────────────────────────────────────────
function Footer({ setPage }) {
  return (
    <footer style={{ background: "#060A12", borderTop: `1px solid ${T.border}`, marginTop: 60, padding: "48px 24px 28px" }}>
      <div style={{ maxWidth: 1400, margin: "0 auto" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 32, marginBottom: 40 }}>
          {/* Brand */}
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 16 }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: "linear-gradient(135deg, #FF8C00, #CC4400)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 900, color: "#000", fontFamily: "'Orbitron', monospace" }}>AX</div>
              <span style={{ fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 14 }} className="shimmer-text">AUTOX</span>
            </div>
            <p style={{ fontSize: 12, color: T.textMuted, lineHeight: 1.7 }}>The world's premium auto parts marketplace. Secure, escrow-protected transactions.</p>
          </div>
          {[
            { title: "Marketplace", links: ["Browse Parts", "Live Auctions", "Make Offers", "Featured Listings", "Vendor Stores"] },
            { title: "Account", links: ["Dashboard", "Wallet", "Orders", "Messages", "Settings"] },
            { title: "Legal", links: ["Terms of Service", "Privacy Policy", "Escrow Policy", "Refund Policy", "Cookie Policy"] },
          ].map(col => (
            <div key={col.title}>
              <div style={{ fontSize: 11, fontWeight: 700, color: T.gold, letterSpacing: 1.5, marginBottom: 14 }}>{col.title.toUpperCase()}</div>
              {col.links.map(link => (
                <div key={link} style={{ fontSize: 12, color: T.textMuted, padding: "4px 0", cursor: "pointer", transition: "color 0.2s" }}
                  onMouseEnter={e => e.target.style.color = T.gold}
                  onMouseLeave={e => e.target.style.color = T.textMuted}
                >{link}</div>
              ))}
            </div>
          ))}
        </div>
        <div style={{ borderTop: `1px solid ${T.border}`, paddingTop: 20, display: "flex", flexWrap: "wrap", justifyContent: "space-between", gap: 12 }}>
          <div style={{ fontSize: 12, color: T.textDim }}>© 2024 AUTOX Marketplace. All rights reserved.</div>
          <div style={{ display: "flex", gap: 16 }}>
            {["PayPal", "Visa", "MC", "Amex"].map(m => (
              <span key={m} className="tag tag-gold" style={{ fontSize: 10 }}>{m}</span>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}

// ─── ROOT APP ─────────────────────────────────────────────────────────────────
export default function AutoXMarketplace() {
  const [page, setPage] = useState("home");
  const [walletBalance, setWalletBalance] = useState(4850);
  const [notifications] = useState(3);

  const renderPage = () => {
    switch (page) {
      case "home": return <HomePage setPage={setPage} walletBalance={walletBalance} setWalletBalance={setWalletBalance} />;
      case "marketplace": return <MarketplacePage setPage={setPage} />;
      case "product": return <ProductPage setPage={setPage} walletBalance={walletBalance} setWalletBalance={setWalletBalance} />;
      case "wallet": return <WalletPage walletBalance={walletBalance} setWalletBalance={setWalletBalance} />;
      case "dashboard": return <DashboardPage setPage={setPage} walletBalance={walletBalance} />;
      case "chat": return <ChatPage />;
      case "auctions": return <AuctionsPage setPage={setPage} />;
      case "admin": return <AdminPage />;
      case "vendor": return <VendorPage setPage={setPage} />;
      default: return <HomePage setPage={setPage} walletBalance={walletBalance} setWalletBalance={setWalletBalance} />;
    }
  };

  return (
    <>
      <style>{GS}</style>
      <div style={{ minHeight: "100vh", background: T.bg }}>
        <Navbar page={page} setPage={setPage} walletBalance={walletBalance} notifications={notifications} />
        
        {/* Page Nav Pills */}
        <div style={{
          background: "rgba(8,12,20,0.95)", borderBottom: `1px solid ${T.border}`,
          padding: "8px 24px", overflowX: "auto",
        }}>
          <div style={{ display: "flex", gap: 6, maxWidth: 1400, margin: "0 auto", width: "max-content" }}>
            {[
              { id: "home", label: "🏠 Home" },
              { id: "marketplace", label: "🔧 Marketplace" },
              { id: "auctions", label: "🔨 Auctions" },
              { id: "product", label: "📄 Product Detail" },
              { id: "wallet", label: "🪙 Wallet" },
              { id: "dashboard", label: "👤 Buyer Dashboard" },
              { id: "chat", label: "💬 Chat" },
              { id: "vendor", label: "🏪 Vendor Panel" },
              { id: "admin", label: "⚙️ Admin Panel" },
            ].map(p => (
              <button key={p.id} onClick={() => setPage(p.id)} style={{
                padding: "5px 14px", borderRadius: 8, fontSize: 12, cursor: "pointer",
                background: page === p.id ? "rgba(255,140,0,0.15)" : "transparent",
                color: page === p.id ? T.gold : T.textMuted,
                border: page === p.id ? "1px solid rgba(255,140,0,0.3)" : "1px solid transparent",
                fontFamily: "'DM Sans', sans-serif",
                transition: "all 0.2s",
                whiteSpace: "nowrap",
              }}>{p.label}</button>
            ))}
          </div>
        </div>

        {renderPage()}
      </div>
    </>
  );
}
