import { AuthCard } from "@/components/auth-card";

export const metadata = {
  title: "Log In | LedgerLens"
};

export default async function LoginPage({ searchParams }) {
  const params = await searchParams;

  return (
    <main className="page-shell">
      <AuthCard email={params?.email || ""} error={params?.error || ""} mode="login" />
    </main>
  );
}
