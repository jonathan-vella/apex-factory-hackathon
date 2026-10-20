// @ts-check
import { defineConfig } from "astro/config";
import { unified } from "@astrojs/markdown-remark";
import sitemap from "@astrojs/sitemap";
import starlight from "@astrojs/starlight";
import rehypeMermaid from "rehype-mermaid-lite";

// https://astro.build/config
export default defineConfig({
  site: "https://factory.apexops.pro",
  base: "/",
  trailingSlash: "always",
  // The module pages were retired: each module's content lives on its challenge pages.
  redirects: {
    "/modules/": "/challenges/",
    "/modules/m0-pre-work/": "/challenges/c00-ready-to-hack/",
    "/modules/m1-foundation/": "/challenges/c01-define-the-opportunity/",
    "/modules/m2-assess-and-decide/": "/challenges/c03-assess-the-source/",
    "/modules/m3-archetype/": "/challenges/c05-deploy-the-coe-archetype/",
    "/modules/m4-modernize-the-app/": "/challenges/c06-modernize-with-ghcp/",
    "/modules/m5-migrate-the-data/": "/challenges/c07-migrate-and-go-live/",
    "/modules/m6-validate-and-optimize/": "/challenges/c08-validate-the-pattern/",
    "/modules/m7-package-and-operate/": "/challenges/c10-package-hand-over-review-ai-readiness/",
  },
  vite: {
    build: {
      chunkSizeWarningLimit: 650,
    },
  },
  markdown: {
    processor: unified({
      rehypePlugins: [rehypeMermaid],
    }),
  },
  integrations: [
    // Coach pages are hidden: keep them out of the sitemap.
    sitemap({ filter: (page) => !new URL(page).pathname.startsWith("/coach/") }),
    starlight({
      title: "Partner Modernization Factory",
      description:
        "Two-day partner hackathon: build a secure Azure foundation, adapt a CoE archetype with APEX and deploy it with azd, and modernize a legacy .NET app and its database with GitHub Copilot and Azure Arc.",
      disable404Route: true,
      favicon: "/images/favicon.svg",
      logo: {
        src: "./src/assets/images/logo.svg",
      },
      editLink: {
        baseUrl: "https://github.com/jonathan-vella/apex-factory-hackathon/edit/main/site/",
      },
      lastUpdated: true,
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/jonathan-vella/apex-factory-hackathon",
        },
      ],
      expressiveCode: {
        styleOverrides: { borderRadius: "0.5rem" },
      },
      sidebar: [
        {
          label: "Getting Started",
          collapsed: true,
          items: [{ autogenerate: { directory: "getting-started" } }],
        },
        {
          label: "Challenges",
          collapsed: true,
          items: [{ autogenerate: { directory: "challenges" } }],
        },
        {
          label: "Guides",
          collapsed: true,
          items: [{ autogenerate: { directory: "guides" } }],
        },
        {
          label: "Prompts",
          collapsed: true,
          items: [
            { label: "Overview", link: "/prompts/" },
            {
              label: "VS Code",
              items: [{ autogenerate: { directory: "prompts/vscode" } }],
            },
            { label: "Copilot app (best effort)", link: "/prompts/copilot-app/" },
          ],
        },
        {
          label: "Reference",
          collapsed: true,
          items: [{ autogenerate: { directory: "reference" } }],
        },
        {
          label: "About",
          collapsed: true,
          items: [{ autogenerate: { directory: "about" } }],
        },
      ],
      customCss: [
        "@fontsource/space-grotesk/400.css",
        "@fontsource/space-grotesk/700.css",
        "@fontsource/manrope/400.css",
        "@fontsource/manrope/700.css",
        "@fontsource/ibm-plex-mono/400.css",
        "@fontsource/ibm-plex-mono/500.css",
        "./src/styles/custom.css",
        "./src/styles/layout.css",
        "./src/styles/tasks.css",
      ],
      components: {
        Footer: "./src/components/Footer.astro",
        PageTitle: "./src/components/PageTitle.astro",
      },
    }),
  ],
});
