import { NextResponse } from "next/server";
import { cors } from "../_lib";

export const runtime = "nodejs";

// Static catalog of the apps Verba supports connecting through Composio.
// Public (no auth): it leaks nothing about any user.
const APPS = [
  { slug: "GMAIL", name: "Gmail", cat: "email" },
  { slug: "GITHUB", name: "GitHub", cat: "developer" },
  { slug: "GOOGLECALENDAR", name: "Google Calendar", cat: "scheduling" },
  { slug: "NOTION", name: "Notion", cat: "notes" },
  { slug: "GOOGLESHEETS", name: "Google Sheets", cat: "spreadsheets" },
  { slug: "SLACK", name: "Slack", cat: "chat" },
  { slug: "OUTLOOK", name: "Outlook", cat: "email" },
  { slug: "TWITTER", name: "Twitter", cat: "social" },
  { slug: "GOOGLEDRIVE", name: "Google Drive", cat: "storage" },
  { slug: "GOOGLEDOCS", name: "Google Docs", cat: "documents" },
  { slug: "HUBSPOT", name: "HubSpot", cat: "crm" },
  { slug: "LINEAR", name: "Linear", cat: "project" },
  { slug: "AIRTABLE", name: "Airtable", cat: "productivity" },
  { slug: "JIRA", name: "Jira", cat: "project" },
  { slug: "YOUTUBE", name: "YouTube", cat: "video" },
  { slug: "GOOGLETASKS", name: "Google Tasks", cat: "tasks" },
  { slug: "DISCORD", name: "Discord", cat: "chat" },
  { slug: "FIGMA", name: "Figma", cat: "design" },
  { slug: "REDDIT", name: "Reddit", cat: "social" },
  { slug: "CAL", name: "Cal.com", cat: "scheduling" },
  { slug: "SENTRY", name: "Sentry", cat: "developer" },
  { slug: "MICROSOFT_TEAMS", name: "Microsoft Teams", cat: "chat" },
  { slug: "ASANA", name: "Asana", cat: "project" },
  { slug: "SHOPIFY", name: "Shopify", cat: "ecommerce" },
  { slug: "LINKEDIN", name: "LinkedIn", cat: "social" },
  { slug: "GOOGLE_MAPS", name: "Google Maps", cat: "maps" },
  { slug: "ONE_DRIVE", name: "OneDrive", cat: "storage" },
  { slug: "DOCUSIGN", name: "DocuSign", cat: "signatures" },
  { slug: "SALESFORCE", name: "Salesforce", cat: "crm" },
  { slug: "CALENDLY", name: "Calendly", cat: "scheduling" },
  { slug: "TRELLO", name: "Trello", cat: "project" },
  { slug: "APOLLO", name: "Apollo", cat: "crm" },
  { slug: "CLICKUP", name: "ClickUp", cat: "productivity" },
  { slug: "STRIPE", name: "Stripe", cat: "payments" },
  { slug: "BREVO", name: "Brevo", cat: "email" },
  { slug: "KLAVIYO", name: "Klaviyo", cat: "marketing" },
  { slug: "POSTHOG", name: "PostHog", cat: "analytics" },
  { slug: "SUPABASE", name: "Supabase", cat: "developer" },
  { slug: "BITBUCKET", name: "Bitbucket", cat: "developer" },
  { slug: "GITLAB", name: "GitLab", cat: "developer" },
  { slug: "DROPBOX", name: "Dropbox", cat: "storage" },
  { slug: "ZOOM", name: "Zoom", cat: "meetings" },
  { slug: "INTERCOM", name: "Intercom", cat: "support" },
  { slug: "ZENDESK", name: "Zendesk", cat: "support" },
  { slug: "MAILCHIMP", name: "Mailchimp", cat: "marketing" },
  { slug: "WHATSAPP", name: "WhatsApp", cat: "chat" },
  { slug: "TELEGRAM", name: "Telegram", cat: "chat" },
  { slug: "SPOTIFY", name: "Spotify", cat: "music" },
  { slug: "TODOIST", name: "Todoist", cat: "tasks" },
  { slug: "AHREFS", name: "Ahrefs", cat: "marketing" },
];

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: cors });
}

export async function GET() {
  return NextResponse.json({ apps: APPS }, { headers: cors });
}
