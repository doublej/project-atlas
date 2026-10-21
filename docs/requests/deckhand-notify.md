# Request: a sessionless `POST /notify` with Allow / Deny on the card

From project-atlas, to the deckhand developer. Nothing here is built in deckhand yet; atlas works
without it.

## What atlas is building

Every `<slug>.atlas.remote.jurrejan.com` dev preview gets a gate. A visitor clicks "Request
access" and gives a name. The request waits for JJ's approval, and approval allowlists the
visitor's IP for that hostname. Today JJ approves in the atlas console or with
`atlas hostnames access --pending`. atlas wants the request on JJ's phone, answered from the
notification itself.

## The route

`POST /notify` on the daemon (`127.0.0.1:4180`), with the Mac token in `x-deckhand-token`, the
same token atlas-api already sends for `/sessions` and `/projects/session`.

```json
{"title": "Access request: <slug>", "line": "<name> from <ip>",
 "actions": [{"id": "approve", "label": "Allow"}, {"id": "deny", "label": "Deny"}],
 "callback": {"url": "http://127.0.0.1:47891/api/hostnames/access",
              "body": {"slug": "<slug>", "id": "<request id>", "action": "$action"}}}
```

Deckhand sends one APNs alert with `title` over `line`, plus the action buttons. When JJ taps one,
deckhand POSTs `callback.body` to `callback.url` from loopback, with every `"$action"` string
value replaced by the tapped action's `id`. atlas-api's write guard already accepts a non-browser
loopback request with no `Origin`, so no token goes the other way.

## Fitting deckhand's notification categories

Buttons can't come from the payload. iOS registers them at launch as `UNNotificationCategory`s
(`DecisionNotes.register()`), and `aps.category` only names one. So the `actions` in the body
have to match a category the app already knows. Proposal:

- One new category, `CALLBACK_ALLOW_DENY`, with Allow (`.authenticationRequired`) and Deny
  (`.authenticationRequired, .destructive`). These are the same options the decision's
  Approve/Deny buttons use, so an Allow from a locked phone still needs an unlock.
- The daemon maps `actions` to a category by its ids (`approve`, `deny`). Labels are only
  checked, never sent. An action set the app has no category for gets a 400. That's better than
  a card with no buttons.

A tap reaches the Mac the same way a decision's button does: signed with `PhoneKey`, to a new
route such as `POST /notify/{id}/answer` with `{action, proof}`. The phone sends only the notify
id and the action id. The callback URL and body stay in the daemon, keyed by notify id, and never
go into the APNs payload. Then neither the caller nor a phone can redirect where deckhand POSTs.

## Responses (proposed)

| Code | When |
|---|---|
| 202 `{"id": "<notify id>"}` | APNs accepted the alert. The id is deckhand's, for its own log. |
| 400 | Blank `title`/`line`, an unknown action set, a bad `callback` (see below), or a body over the cap. |
| 401 | Wrong or missing token. |
| 503 `{"detail": "..."}` | No alert can go out. Either there's no device token ("the phone has not allowed notifications yet") or no push key on this Mac. This is `sending.alert`'s own error text. |
| 502 `{"detail": "..."}` | APNs refused or couldn't be reached. |

Please report what APNs actually said. `features.md` notes that `/sessions/{id}/notify` answers
`pushed: true` even when the send failed. For this route, a 202 should mean the card was sent.

## Refusals

- `callback.url` must be `http://127.0.0.1:<port>/...` or `http://localhost:<port>/...`. No
  https, no other host, no userinfo, no redirects followed. Otherwise this route becomes a way to
  make the daemon POST anywhere.
- `callback.body` must be a JSON object. Only exact `"$action"` string values are substituted,
  never parts of strings and never keys.
- Body cap: 4 KB is plenty (title and line under 200 characters each, at most 4 actions).
- `title` and `line` are text, shortened the way `push.shortened` already shortens.

## When the callback fails

- **2xx**: done. Log one line.
- **404**: the request was already decided in the console, or it expired on the atlas side.
  Drop it, log one line, show nothing on the phone.
- **Anything else, or atlas-api down**: the phone's tap gets an error back, and the app shows its
  existing "Not answered — <why>" note (`DecisionNotes.tell`). JJ can still decide in the
  console. One retry after a few seconds is fine. Please don't loop: atlas-api restarts through
  its watchdog, and by then JJ may already have answered somewhere else.

## Expiry and idempotency

- `apns-collapse-id: notify:<id>`, so a re-send replaces the card instead of stacking.
- The daemon keeps each callback for 24 hours, then forgets it. A tap after that answers
  "expired" through the same "Not answered" note.
- One notify id gets one callback. A second tap (two devices, a retry) is answered from the first
  result and is never POSTed again. atlas also handles a repeat safely: deciding a request that
  is already decided gets a 404.

## Why `/sessions/{id}/notify` doesn't fit

- There's no session. The request comes from a visitor on a dev hostname, not from an agent, so
  there's no `session_id` to put in the path, and `session_or_404` would refuse it.
- That route carries the folder's `called` switch, the right of a folder to refuse being
  interrupted by its own agent. A visitor asking JJ for access isn't any folder's agent, so the
  switch doesn't apply.
- It takes only `{line}` and goes into the session's Live Activity. This needs a plain alert with
  buttons, and a way back to the caller that the decision path doesn't have.

## Until the route exists

atlas-api calls `POST /notify` once per access request. On a 404 it logs one line and carries on,
and the request waits in `atlas hostnames access --pending` and the console. Nothing in atlas
depends on the phone card. It's a faster way to answer, not the only way.
