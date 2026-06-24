import type { Metadata } from "next";
import LegalDoc from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Contact, Verba",
  description: "Get in touch with the Verba team at Agentik OS for support or questions.",
  alternates: { canonical: "/contact" },
};

const MD = `## Contact Verba

Verba is a product of **Agentik {OS}**, operated by **Dafnck Studio** (Entreprise Individuelle), founded by Gareth Simono and based in Paris, France.

## Get in touch

- **General & support:** [hello@agentik-os.com](mailto:hello@agentik-os.com)
- **Privacy & data requests:** [studio@dafnck.com](mailto:studio@dafnck.com)

## Support & reporting issues

- For help with your subscription, billing, account, or a feature, email **hello@agentik-os.com**.
- To report a bug or request a feature, open an issue on our GitHub releases page, where Verba is distributed: [github.com/agentik-os](https://github.com/agentik-os).
- For privacy, data-access, correction, or deletion requests, email **studio@dafnck.com**.

We aim to respond to all messages as quickly as we can.`;

export default function Page() {
  return <LegalDoc title="Contact" md={MD} />;
}
