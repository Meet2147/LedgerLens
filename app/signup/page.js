import { AuthCard } from "@/components/auth-card";

export const metadata = {
  title: "Sign Up | LedgerLens"
};

export default async function SignupPage({ searchParams }) {
  const params = await searchParams;

  return (
    <main className="page-shell">
      <AuthCard
        email={params?.email || ""}
        error={params?.error || ""}
        mode="signup"
        selectedBilling={(params?.billing || "monthly").toLowerCase()}
        selectedTier={(params?.tier || "personal").toLowerCase()}
      />
    </main>
  );
}
