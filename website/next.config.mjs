/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Force the canonical host: 301 www.verba.run → verba.run so the www variant never
  // resolves as a duplicate (the canonical tag already points here; this enforces it server-side).
  async redirects() {
    return [
      {
        source: "/:path*",
        has: [{ type: "host", value: "www.verba.run" }],
        destination: "https://verba.run/:path*",
        permanent: true,
      },
    ];
  },
};
export default nextConfig;
