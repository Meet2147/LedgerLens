import Link from "next/link";
import { UploadWorkbench } from "@/components/upload-workbench";
import { getCurrentUser } from "@/lib/auth";

export const metadata = {
  title: "Converter | LedgerLens"
};

export default async function ConverterPage() {
  const currentUser = await getCurrentUser();

  return (
    <main className="page-shell">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Converter</div>
          <h1>Upload, convert, preview, and export.</h1>
          <p className="hero-copy">
            This is the working conversion workspace. Upload a PDF statement, enter a password if
            it is protected, inspect the preview, then export the result as CSV or XLSX.
          </p>
          <p className="section-copy">
            Privacy note: we do not store your uploaded PDFs or the transaction data parsed from
            them. The file is processed only for conversion.
          </p>
          {currentUser ? (
            <div className="status-banner">
              Signed in as <strong>{currentUser.email}</strong> on the <strong>{currentUser.tier}</strong>{" "}
              tier.
            </div>
          ) : (
            <div className="status-banner muted-banner">
              You can test the converter without an account, but signing up lets us track your tier.
              <Link href="/signup" className="inline-link">
                Create an account
              </Link>
            </div>
          )}
        </div>
      </section>

      <UploadWorkbench />
    </main>
  );
}
