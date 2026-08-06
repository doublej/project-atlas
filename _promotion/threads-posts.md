# Threads Posts — project-atlas

## Post 1: Pain → Solution

I have 120+ dev projects across 8 languages. Finding the right one used to mean `ls`, `cd`, scroll, repeat.

So I built a local API that scans everything — detects the framework, package manager, git status, scripts, justfile recipes — and serves it all as JSON.

Now I open Raycast, type two letters, and I'm there.

What's your project navigation setup?

> **Posting note:** Conversational opener. No link. The question at the end should drive replies. Post on a weekday evening. Reply to every comment within the first hour.

---

## Post 2: Behind the Scenes

The thing about building dev tools for yourself is you discover what you actually need vs. what you think you need.

I started with a simple folder scanner. Ended up with:
- A SvelteKit API that caches and refreshes in the background
- A Raycast extension for search and quick actions
- A Rust TUI for when I'm already in the terminal
- A bash monitor that auto-restarts the service if it goes down

Four components. One job: stop wasting time finding projects.

> **Posting note:** Build-in-public angle. If you have a screenshot of the Raycast extension or the TUI, attach it — visual posts outperform text-only on Threads. Carousel of all four components would be ideal.

---

## Post 3: Show, Don't Tell

Nobody talks about this but opening a project is more than `cd`-ing into a folder.

You need to know: what's the package manager? Are there uncommitted changes? What scripts are available? Is there a justfile?

I built a scanner that detects all of that automatically across Node, Python, Rust, Go, and Swift projects. One API call, everything you need.

> **Posting note:** Leads with insight, ends with the value prop. Good candidate for a carousel showing detection output for different project types. Post as a follow-up 1-2 days after Post 1.

---

## Post 4: Contrarian

Hot take: you don't need a fancy project manager to navigate a large codebase collection.

You need three things:
1. A scanner that understands your stack
2. A fast way to search
3. One-click actions (open terminal, run dev server, check git)

That's it. No dashboards. No config files. Just detection and speed.

> **Posting note:** Hot take format performs well on Threads. Keep it punchy. This works as a standalone post or as a series starter.

---

## Post 5: Direct Value

How I navigate 120+ projects in under 2 seconds:

Raycast → type project name → Enter.

Behind that keystroke: a SvelteKit API scans my entire dev folder, detects frameworks and tools, caches results with stale-while-revalidate, and the Raycast extension consumes it all.

The Rust TUI does the same thing from the terminal with fuzzy search.

Zero config. It just reads your manifests.

> **Posting note:** "How I do X" format. Concrete number (2 seconds, 120+ projects) makes it tangible. Good for weekday posting when devs are active. If you have a screen recording of the flow, attach it.
