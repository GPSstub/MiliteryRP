# Discord-style Military Messenger — Implementation Contract

Status: DESIGN ONLY. This document is not a claim that the features below are implemented.

## Official behavior references
- Discord channel and category permissions: https://support.discord.com/hc/en-us/articles/206029707-Setting-Up-Permissions-FAQ
- Discord message history permissions: https://support.discord.com/hc/en-us/articles/10543994968087-Channel-Permissions-Settings-101
- Discord search: https://support.discord.com/hc/en-us/articles/115000468588-How-to-Use-Search-on-Discord
- Discord pins: https://support.discord.com/hc/en-us/articles/221421867-Pin-Messages-FAQ
- Discord message editing: https://support.discord.com/hc/en-us/articles/207618817-How-do-I-edit-my-messages
- Roblox text filtering: https://create.roblox.com/docs/ui/text-filtering
- Roblox DataStore limits: https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits

## Existing code to preserve
- `src/server/MessengerStore.luau`: persistent channels/categories/roles, Studio/prod separation.
- `src/server/MessengerPermissions.luau`: server-side channel ACL.
- `src/server/MessengerRuntime.luau`: TextChatService channel delivery.
- `src/client/MilitaryMessenger.client.luau`: chat UI, currently ephemeral local history.
- `src/client/MessengerAdmin.client.luau`: management UI.
- `src/server/RankStore.luau`: rank persistence added on main; user has locally merged it into this feature branch. Preserve that merge when integrating.

## Proposed staged implementation
1. Durable per-channel message archive with append-only IDs, bounded DataStore pages, cursor-based older-message pagination, idempotent writes and retry/backpressure. Do not put an unbounded chat log in one DataStore key.
2. On-demand history fetch RemoteFunction with per-request server-side READ and READ_HISTORY checks, pagination size caps and request throttling. Recheck access before every history response.
3. Persistent metadata: edit (author only), delete (author or manage permission), pin/unpin (manage permission), reactions, reply references, and audit trails. Every mutation uses server-side authorization and version checks.
4. Search across authorized channel archives using bounded indexed metadata, server-side filters and paged results. Avoid full-store scans.
5. Discord-like UI: lazy history loading when scrolling upward, jump to message, search filters, message action menu, pinned list, unread markers, reply previews and threads.
6. Cross-server updates via MessagingService as a notification hint, with reconciliation against durable storage; never treat PubSub delivery as a durable commit.
7. Studio tests: permission denial, text filtering failures, offline/rejoin history, concurrent sends, retry idempotency, old/new server synchronization, rate limits, edit/delete races.

## Mandatory Roblox safety requirements
- Do not persist unfiltered player-authored chat or display saved text without appropriate Roblox filtering for the viewing audience. Live TextChatService automatic filtering does not automatically validate custom archived UI replay.
- Enforce Roblox communication eligibility, blocked users and channel permissions on the server, not only in GUI.
- DataStore requests have throttling, per-key throughput and size limits; choose sharded/paged storage and bounded write frequency.
- Separate Studio development and production stores, as existing configuration persistence already does.
- Do not silently discard messages after claiming archival success. Expose save state and failures.
- The full Discord product (voice/video calls, external file uploads, bots, Nitro, etc.) is not equivalent to a Roblox in-experience messenger and cannot be promised as a drop-in clone.

## Acceptance checks
- Send -> wait for durable acknowledgment -> Stop/Play -> message appears in correct channel.
- Two server instances -> same history after sync.
- A player without channel access cannot fetch messages by guessing a channel ID.
- Edit/delete/pin permissions enforced server-side.
- Page boundaries and rapid sends do not duplicate or lose messages.
- Message text remains appropriately filtered on all replay paths.
