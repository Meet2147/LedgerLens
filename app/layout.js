import "./globals.css";
import { SiteHeader } from "@/components/site-header";
import { getCurrentUser } from "@/lib/auth";

export const metadata = {
  title: "LedgerLens | Convert Bank Statements to Excel and CSV",
  description:
    "Password-aware bank statement conversion for accountants, finance teams, and operators.",
  icons: {
    icon: "/icon.svg?v=4",
    shortcut: "/icon.svg?v=4",
    apple: "/icon.svg?v=4"
  }
};

export default async function RootLayout({ children }) {
  const currentUser = await getCurrentUser();

  return (
    <html lang="en">
      <body suppressHydrationWarning>
        <div className="app-frame">
          <SiteHeader currentUser={currentUser} />
          {children}
        </div>
      </body>
    </html>
  );
}
