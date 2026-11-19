function detail(value, placeholder) {
  return value?.trim() || `[${placeholder}]`;
}

export function createEventDrafts(details = {}) {
  const setupMode =
    details.setupMode?.trim() === "lead-provisioned" ? "lead-provisioned" : "self-service";
  const organizer = detail(details.organizer, "organizer name");
  const contact = detail(details.contact, "team lead or organizer contact");
  const briefingWhen = detail(details.briefingWhen, "briefing date and time, including time zone");
  const briefingLocation = detail(details.briefingLocation, "briefing location or meeting link");
  const dayOne = detail(details.dayOne, "day 1 date");
  const dayTwo = detail(details.dayTwo, "day 2 date");
  const dayOneTime = detail(details.dayOneTime, "day 1 time");
  const dayTwoTime = detail(details.dayTwoTime, "day 2 time");
  const timeZone = detail(details.timeZone, "time zone");
  const eventLocation = detail(details.eventLocation, "event location or meeting link");
  const resources = detail(details.resources, "event materials and setup link");

  if (setupMode === "lead-provisioned") {
    const leadGuides = `Event overview: https://factory.apexops.pro/getting-started/event-overview/
Requirements: https://factory.apexops.pro/getting-started/requirements/
Roles: https://factory.apexops.pro/getting-started/roles/
Student onboarding: https://factory.apexops.pro/deploy/lead-setup/student-onboarding/
Lead cohort setup: https://factory.apexops.pro/deploy/lead-setup/step-1-cohort-and-preflight/`;

    return [
      {
        id: "overview-email",
        title: "Overview email",
        text: `Subject: Partner Modernization Factory hackathon: overview and preparation

Hi everyone,

You're invited to the Partner Modernization Factory, a two-day, hands-on hackathon for Microsoft partners.

Working as a delivery team for fictional Contoso University, you'll assess its legacy application, choose a target state, deploy a reusable CoE archetype, modernize the application, migrate its database and prepare a handover. Larger cohorts split into breakout pods of three to five people for team challenges. This is a non-production learning lab.

Know Before You Go

Join the briefing on ${briefingWhen} at ${briefingLocation}. We'll introduce the scenario, explain the hackathon, review student onboarding and answer questions.

Before the briefing, read the Event overview, Requirements and Roles guides below.

Event materials: ${resources}
${leadGuides}

How pre-event setup works (lead-provisioned cohort)

- Your platform team lead pre-creates your private GitHub repository and deploys the shared landing zone, your simulated datacenter and spoke vending ahead of Day 1 (including the T-7 directory grant after foundation deployment and tenant-owner approval). You do not need to create a repository from a template or run the T-14 to T-1 deployment pipelines yourself.
- Reply privately to your team lead with your GitHub username (and your Microsoft Entra object ID and work email if requested), then accept the GitHub repository invitation as soon as it arrives.
- Each attendee needs unconditional Owner on their assigned paid workload subscription, MFA, and a GitHub account with a paid GitHub Copilot seat (with agent mode, MCP servers and required models allowed). Check Windows 11 licensing and Windows Server Azure Hybrid Benefit entitlement in the Requirements guide.
- Once your team lead confirms your environment is vended, connect to vm-dev01 through Azure Bastion in your browser and complete Student onboarding before Day 1.

No coach is on duty during pre-event setup. Your designated team lead is your first point of contact, and support before the event is best-effort. Share your GitHub username and account details privately, not in public channels.

Event details

Know Before You Go: ${briefingWhen}
Day 1: ${dayOne}, ${dayOneTime} ${timeZone}
Day 2: ${dayTwo}, ${dayTwoTime} ${timeZone}
Event location: ${eventLocation}
Contact: ${contact}

Best,
${organizer}`,
      },
      {
        id: "briefing-invite",
        title: "Know Before You Go invitation",
        text: `Title: Partner Modernization Factory - Know Before You Go
Date and time: ${briefingWhen}
Location: ${briefingLocation}
Organizer: ${organizer}

Join us for a briefing ahead of the Partner Modernization Factory hackathon. We'll introduce the Contoso University scenario, explain the two-day event, and walk through student onboarding for our lead-provisioned cohort.

We'll cover:

- The hackathon's goals and challenge journey
- Team and breakout-pod roles and how the work is organized
- GitHub, Copilot, Azure and workstation requirements
- How lead-provisioned setup works: sharing your GitHub username privately, accepting your repository invitation and completing Student onboarding
- Questions and next steps

Before the briefing, read the Event overview, Requirements and Roles guides below.

Event materials: ${resources}
${leadGuides}

Your team lead provisions the repositories and pre-event Azure infrastructure; attendees do not run the T-14 to T-1 pipelines themselves. Reply privately with your GitHub username, accept your repository invitation, and complete Student onboarding before Day 1.

Bring any access or workstation questions. Your designated team lead is the first point of contact for pre-event blockers; support before the event is best-effort.

Contact: ${contact}`,
      },
      {
        id: "hackathon-invite",
        title: "Hackathon invitation",
        text: `Title: Partner Modernization Factory - Two-Day Hackathon
Day 1: ${dayOne}, ${dayOneTime} ${timeZone}
Day 2: ${dayTwo}, ${dayTwoTime} ${timeZone}
Location: ${eventLocation}
Organizer: ${organizer}

Join us for the Partner Modernization Factory, a two-day, hands-on hackathon for Microsoft partners.

You'll work as a delivery team for fictional Contoso University, modernizing its legacy enrollment application and exploring a repeatable approach for customer engagements. The work moves from customer outcomes and architecture decisions through application modernization, database migration, validation and handover.

Day 1 includes the kickoff, customer-outcome and assessment activities, target-state decisions, CoE archetype deployment and the start of application modernization. Day 2 continues modernization, then focuses on migration and go-live, validation, database optimization and handover.

Please arrive with your Student onboarding complete:

- You have accepted your GitHub repository invitation.
- Your assigned Azure access is in place, including unconditional Owner on your own workload subscription.
- Your team lead has deployed your datacenter and vended your spoke. You have connected to vm-dev01 through Bastion, opened your repo and verified Copilot Chat.
- Both datacenter VMs are running when you arrive. Keep vm-dev01 running throughout the event.

Bring your laptop and any setup questions. Review the event materials and student onboarding guide: ${resources}

${leadGuides}

Share account details privately with your team lead, not in public channels. The standard Day 1 plan starts with the kickoff at 08:30 and C1 at 09:00; confirm any changes for your event.

Contact: ${contact}`,
      },
    ];
  }

  const guides = `Event overview: https://factory.apexops.pro/getting-started/event-overview/
Requirements: https://factory.apexops.pro/getting-started/requirements/
Roles: https://factory.apexops.pro/getting-started/roles/
Deploy: https://factory.apexops.pro/deploy/`;

  return [
    {
      id: "overview-email",
      title: "Overview email",
      text: `Subject: Partner Modernization Factory hackathon: overview and preparation

Hi everyone,

You're invited to the Partner Modernization Factory, a two-day, hands-on hackathon for Microsoft partners.

Working in teams, you'll act as a delivery team for fictional Contoso University. You'll assess its legacy application, choose a target state, deploy a reusable CoE archetype, modernize the application, migrate its database and prepare a handover. This is a non-production learning lab.

Know Before You Go

Join the briefing on ${briefingWhen} at ${briefingLocation}. We'll introduce the scenario, explain the hackathon, review preparation milestones and answer questions.

Before the briefing, read the Event overview, Requirements and Roles guides below.

Event materials: ${resources}
${guides}

High-level requirements

- Each platform team shares a dedicated non-production Entra tenant and empty, supported paid subscriptions: one shared-services subscription per hub and one workload subscription per member, including a nominated team lead (larger cohorts group into breakout pods of three to five people for team challenges). Each member needs unconditional Owner on their workload subscription and MFA.
- Each member needs a GitHub account in the partner organization, a private repository and a paid GitHub Copilot seat. The organization's policies must allow agent mode, MCP servers and the required models. Verify GitHub plan support and Actions billing.
- Start setup in Azure Cloud Shell in your browser. For the challenges, connect to vm-dev01 through Azure Bastion and use the tools on that workstation. Check Windows 11 licensing, Windows Server Azure Hybrid Benefit entitlement and regional Azure quota in the Requirements guide. Preflight does not check quota or subscription offer type.
- The team lead additionally needs Owner on shared services and at Tenant Root. Book a Privileged Role Administrator for the T-7 directory grant, which follows foundation deployment and tenant-owner approval.

Preparation happens in stages: repository setup and preflight by T-14; shared foundation and directory permissions at T-7; each member's datacenter, assessment and workstation by T-3; and team vending at T-1. Allow time for access and quota requests.

No coach is on duty during pre-event setup. Your designated team lead is your first point of contact, and support before the event is best-effort. Share roster information privately, not in public channels.

Event details

Know Before You Go: ${briefingWhen}
Day 1: ${dayOne}, ${dayOneTime} ${timeZone}
Day 2: ${dayTwo}, ${dayTwoTime} ${timeZone}
Event location: ${eventLocation}
Contact: ${contact}

Best,
${organizer}`,
    },
    {
      id: "briefing-invite",
      title: "Know Before You Go invitation",
      text: `Title: Partner Modernization Factory - Know Before You Go
Date and time: ${briefingWhen}
Location: ${briefingLocation}
Organizer: ${organizer}

Join us for a briefing ahead of the Partner Modernization Factory hackathon. We'll introduce the Contoso University scenario, explain the two-day event, and review the requirements and preparation milestones.

We'll cover:

- The hackathon's goals and challenge journey
- Team roles and how the work is organized
- GitHub, Copilot, Azure and workstation requirements
- Preparation milestones: T-14, T-7, T-3 and T-1
- Questions and next steps

Before the briefing, read the Event overview, Requirements and Roles guides below.

Event materials: ${resources}
${guides}

Before the hackathon, complete the four numbered Deploy steps (T-14, T-7, T-3 and T-1).

Bring any access or setup questions. Your designated team lead is the first point of contact for pre-event blockers; support before the event is best-effort.

Contact: ${contact}`,
    },
    {
      id: "hackathon-invite",
      title: "Hackathon invitation",
      text: `Title: Partner Modernization Factory - Two-Day Hackathon
Day 1: ${dayOne}, ${dayOneTime} ${timeZone}
Day 2: ${dayTwo}, ${dayTwoTime} ${timeZone}
Location: ${eventLocation}
Organizer: ${organizer}

Join us for the Partner Modernization Factory, a two-day, hands-on hackathon for Microsoft partners.

You'll work as a delivery team for fictional Contoso University, modernizing its legacy enrollment application and exploring a repeatable approach for customer engagements. The work moves from customer outcomes and architecture decisions through application modernization, database migration, validation and handover.

Day 1 includes the kickoff, customer-outcome and assessment activities, target-state decisions, CoE archetype deployment and the start of application modernization. Day 2 continues modernization, then focuses on migration and go-live, validation, database optimization and handover.

Please arrive with your pre-event setup complete:

- Your private GitHub repository and Copilot-enabled development environment are ready, and preflight is complete.
- Your assigned Azure access is in place, including unconditional Owner on your own workload subscription.
- Your datacenter is deployed and tested, vm-app01 is connected to Azure Arc, vm-dev01 is set up, and your team lead has completed vending.
- Both datacenter VMs are running when you arrive. Keep vm-dev01 running throughout the event.

Bring your laptop and any setup questions. Review the event materials and setup guide: ${resources}

${guides}

Share roster information privately with your team lead, not in public channels. The standard Day 1 plan starts with the kickoff at 08:30 and C1 at 09:00; confirm any changes for your event.

Contact: ${contact}`,
    },
  ];
}

export function initEventMaterials() {
  const root = document.querySelector("[data-event-materials]");
  if (!root) return;

  const status = root.querySelector("[data-status]");
  const generate = root.querySelector("[data-generate]");
  const fields = root.querySelectorAll("input[name], select[name]");

  generate.hidden = false;
  generate.addEventListener("click", () => {
    const details = Object.fromEntries([...fields].map((field) => [field.name, field.value]));
    for (const draft of createEventDrafts(details)) {
      root.querySelector(`#${draft.id}`).value = draft.text;
    }
    for (const feedback of root.querySelectorAll("[data-copy-status]")) {
      feedback.textContent = "";
    }
    status.textContent = "Drafts generated. Review and edit them before sharing.";
  });

  for (const button of root.querySelectorAll("[data-copy]")) {
    const output = root.querySelector(`#${button.dataset.copy}`);
    const feedback = root.querySelector(`[data-copy-status="${button.dataset.copy}"]`);
    button.hidden = false;
    output.addEventListener("input", () => {
      feedback.textContent = "";
    });
    button.addEventListener("click", async () => {
      if (!navigator.clipboard?.writeText) {
        output.focus();
        output.select();
        feedback.textContent =
          "Clipboard access is unavailable. The draft is selected; copy it manually.";
        return;
      }

      try {
        await navigator.clipboard.writeText(output.value);
        feedback.textContent = `${button.dataset.title} copied.`;
      } catch {
        output.focus();
        output.select();
        feedback.textContent =
          "Could not copy to the clipboard. The draft is selected; copy it manually.";
      }
    });
  }
}
