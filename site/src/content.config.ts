import { defineCollection } from "astro:content";
import { docsLoader } from "@astrojs/starlight/loaders";
import { docsSchema } from "@astrojs/starlight/schema";
import { coachLoader, coachSchema } from "./lib/coach-loader";

export const collections = {
  docs: defineCollection({ loader: docsLoader(), schema: docsSchema() }),
  coach: defineCollection({ loader: coachLoader(), schema: coachSchema }),
};
