import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/context/AuthContext";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
});

export const metadata: Metadata = {
  title: "Tarang — Every Voice Creates a Wave",
  description: "Connect people through conversations that spread like waves. Discover community currents, rise with the tide, and make ripples.",
  keywords: ["Tarang", "Wave", "Social Media", "Ocean", "India", "Riders", "Circles"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${outfit.variable}`}>
      <head>
        <link rel="icon" href="/favicon.ico" />
      </head>
      <body className="antialiased selection:bg-foam selection:text-ocean">
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
