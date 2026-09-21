# Local project inventory

## Summary

- Total local, non-archived projects: 458
- By bucket:
  - cli-or-lib: 135
  - python-service: 10
  - unknown: 41
  - web-dev-server: 272
- By type:
  - generic: 5
  - go: 3
  - node: 251
  - python: 140
  - rust: 11
  - swift: 32
  - workspace: 16
- Have .atlas file: 106
- Have a detected port: 17
- Have a justfile dev/run/serve/start recipe: 106
- Have a registered dev hostname: 2

## Migration candidates

- Total candidates: 230
  - T1: 12
    - node: 12
  - T2: 165
    - node: 165
  - T3: 18
    - node: 1
    - rust: 2
    - swift: 10
    - workspace: 5
  - T4: 31
    - node: 1
    - python: 30
  - T5: 4
    - node: 2
    - python: 2
- Nested (monorepo child of another candidate): 0

### Tier by activity

| tier | active90 | active365 | stale | none |
|---|---|---|---|---|
| T1 | 9 | 0 | 0 | 3 |
| T2 | 33 | 84 | 11 | 37 |
| T3 | 8 | 8 | 0 | 2 |
| T4 | 9 | 12 | 5 | 5 |
| T5 | 0 | 2 | 0 | 2 |

### active90 candidates (59)

| path | tier | runner | port | hardcodedPort |
|---|---|---|---|---|
| _management/claude-history-browser | T2 | bun | - | 5181 |
| _management/strandkanban | T2 | bun | - | - |
| app/poolsuite | T1 | bun | 4107 | 4107 |
| games/spplx | T1 | bun | 4110 | 4110 |
| mcp/consult-user-mcp | T2 | bun | - | - |
| misc/TheOcularMigraineMCP | T2 | bun | - | - |
| multi-stack/flights | T3 | bun | - | - |
| multi-stack/frameclarity | T3 | - | - | - |
| multi-stack/framelink/app | T2 | bun | - | - |
| multi-stack/framelink/auth | T2 | bun | - | - |
| multi-stack/framelink/broker | T2 | bun | - | - |
| multi-stack/framelink/homepage | T1 | bun | 5175 | 5175 |
| multi-stack/pimpelmees | T3 | - | - | - |
| multi-stack/redline | T3 | - | 4105 | - |
| multi-stack/sideload | T3 | - | 4108 | - |
| multi-stack/simsync-mono | T2 | bun | - | - |
| node/beads-sdk | T2 | bun | - | - |
| node/caddyctl | T2 | bun | - | - |
| node/claude-activity-watcher | T2 | bun | - | - |
| node/group-chat-bud | T2 | bun | - | - |
| node/onenv | T2 | bun | - | - |
| node/troostwijk-auction-tools | T2 | bun | - | - |
| node/umami-cli | T2 | bun | - | - |
| python/finances | T4 | uv | 8000 | - |
| python/hyndsyght | T4 | uv | - | - |
| python/parakeet-server | T4 | uv | - | - |
| python/playlistbuilder-node | T2 | bun | - | - |
| python/plume | T4 | uv | - | - |
| python/poolsuite-partners-invoice-generator | T4 | uv | - | - |
| python/schakelwerk | T4 | uv | - | - |
| python/shazamap | T4 | uv | - | - |
| python/uttertype | T4 | uv | - | - |
| python/utty | T3 | - | - | - |
| raycast/gif-search | T2 | npm | - | - |
| raycast/raycast-ext-active-ports | T2 | bun | - | - |
| raycast/raycast-ext-file-scripts | T2 | bun | - | - |
| swift/continuity | T3 | - | - | - |
| swift/utt | T3 | - | - | - |
| video/kfcut | T4 | uv | 8770 | 8770 |
| web/MAHORAGA | T2 | npm | - | - |
| web/assetto-corsa-evo-replay-visualizer | T2 | bun | - | - |
| web/festival-timetable | T1 | bun | 5180 | 5180 |
| web/gta-vreeswijk | T2 | bun | - | - |
| web/mermaid-gantt | T2 | bun | - | - |
| web/midjourney-prompt-builder | T1 | bun | 5190 | 5190 |
| web/monotyco | T2 | bun | - | 49173 |
| web/obs-remote | T2 | bun | - | - |
| web/offerte | T2 | bun | - | 47333 |
| web/personal-homepage-simple | T1 | bun | 4101 | 4101 |
| web/photoshop-image-gpt-2-plugin | T2 | - | - | - |
| web/poolsuite/poolsuite-pager | T2 | bun | - | - |
| web/prettygoodtime | T1 | bun | 5193 | 5193 |
| web/psp-network | T2 | bun | - | - |
| web/realtor-photo-preview | T2 | bun | - | - |
| web/the-ultimate-music-quiz | T2 | bun | - | - |
| web/umami | T2 | pnpm | - | - |
| web/unsubscribe-sanctuary | T1 | bun | 4106 | 4106 |
| web/utt-website | T1 | bun | 4102 | 4102 |
| web/wildeburg-timetable | T2 | bun | - | - |

### Duplicate slugs (0)

- none

### Slugs over 63 chars (0)

- none

### Hardcoded ports outside 4100-4999 (41)

- _management/claude-history-browser: port 5181
- _sandbox/broken_ball: port 5199
- _sandbox/buurtpuzzelmap: port 5173
- _sandbox/clouds: port 5180
- _sandbox/finances: port 8000
- _sandbox/homebrew-tracker: port 5173
- _sandbox/phone-finder: port 5173
- misc/cui: port 5173
- multi-stack/framelink/homepage: port 5175
- python/fb-scrape: port 8000
- python/funda-scraper-scrapling: port 8000
- python/haist-qr: port 3749
- python/haist-qr-web: port 5174
- python/haist-qr-web-shadcn: port 5174
- rust/alvr-webui: port 3000
- video/kfcut: port 8770
- web/create_li_post: port 3000
- web/element-filter: port 3000
- web/festival-timetable: port 5180
- web/haist-v2/frontend: port 5173
- web/info-map-view: port 5173
- web/jamesexpress: port 48173
- web/midjourney-prompt-builder: port 5190
- web/minority: port 3000
- web/monotyco: port 49173
- web/offerte: port 47333
- web/personal-www-2: port 5173
- web/pixi-paper: port 5847
- web/poolsuite/pixi-adaptive-glass: port 5173
- web/poolsuite/pixi-v8_glass: port 3001
- web/poolsuite/pixi-v8_glass_codex: port 5173
- web/poolsuite/silentsongs_alt: port 9009
- web/prettygoodtime: port 5193
- web/segment-display: port 5183
- web/shader-poolsuite-partners-logo: port 33891
- web/siargao-weather: port 5891
- web/soundcloud-api-test: port 5174
- web/ss-glass: port 3000
- web/ss-glass-module: port 3000
- web/turkey_spend: port 8765
- web/umbrella: port 5847

## cli-or-lib (135)

| path | name | slug | type | framework | runner | git owner | flow | justfile | pkg dev/start | port | hostname | .atlas | candidate | tier | nested | hardcodedPort | slugDup | slugLong |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| _life/system/app | app | life-system-app | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _management/claude-team-launcher | claude-team-launcher | management-claude-team-launcher | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _management/dotfiles/submodules/dotbot | dotbot | management-dotfiles-submodules-dotbot | python | unknown | - | anishathalye | external | - | - | - | - | - | - | - | - | - | - | - |
| _management/promotion-vault | promotion-vault | management-promotion-vault | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _management/prompt-analysis | prompt-analysis | management-prompt-analysis | python | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| _management/you-are-a-strong-confident-llm | you-are-a-strong-confident-llm | management-you-are-a-strong-confident-llm | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/browser | browser | sandbox-browser | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/discord_chats/auth | auth | sandbox-discord-chats-auth | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/discord_chats/poc_rag | poc_rag | sandbox-discord-chats-poc-rag | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/env | env | sandbox-env | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/fastfont | fastfont | sandbox-fastfont | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/folega | folega | sandbox-folega | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/haptics | haptics | sandbox-haptics | node | svelte | bun | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/imgrec | imgrec | sandbox-imgrec | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/organizegpt | organizegpt | sandbox-organizegpt | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/raster_2_vector/vtracer | vtracer | sandbox-raster-2-vector-vtracer | rust | unknown | - | visioncortex | external | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/stem-separation | stem-separation | sandbox-stem-separation | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/ui-sounds | ui-sounds | sandbox-ui-sounds | node | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| audio/cdj-tapestop | cdj-tapestop | audio-cdj-tapestop | rust | unknown | - | - | local | - | - | - | - | - | - | - | - | - | - | - |
| audio/race-agent | race-agent | audio-race-agent | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| design/pharmacy-sign | pharmacy-sign | design-pharmacy-sign | python | unknown | uv | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| games/a2racer-assets | a2racer-assets | games-a2racer-assets | python | unknown | uv | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| generative_ai/claude_cam/ezviz_downloader/js-sdk | js-sdk | generative-ai-claude-cam-ezviz-downloader-js-sdk | node | unknown | npm | - | - | - | - | - | - | - | - | - | - | - | - | - |
| generative_ai/claude_cam/wiremcp | wiremcp | generative-ai-claude-cam-wiremcp | node | unknown | bun | 0xkoda | external | - | - | - | - | - | - | - | - | - | - | - |
| generative_ai/depth_anything | depth_anything | generative-ai-depth-anything | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| misc/stereocrafter | stereocrafter | misc-stereocrafter | python | unknown | uv | TencentARC | external | - | - | - | - | - | - | - | - | - | - | - |
| multi-stack/agency | agency | multi-stack-agency | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| multi-stack/alvr | alvr | multi-stack-alvr | rust | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| node/claude-dispatch-tests | claude-dispatch-tests | node-claude-dispatch-tests | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| node/fb-group-scraper | fb-group-scraper | node-fb-group-scraper | node | unknown | bun | - | - | - | - | - | - | - | - | - | - | - | - | - |
| node/npo-dl | npo-dl | node-npo-dl | node | unknown | npm | Ewoodss | external | - | - | - | - | - | - | - | - | - | - | - |
| node/orphan-obliterator | orphan-obliterator | node-orphan-obliterator | node | unknown | bun | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| node/statiehelden | statiehelden | node-statiehelden | node | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| node/swcache | swcache | node-swcache | node | unknown | bun | - | local | - | - | - | - | - | - | - | - | - | - | - |
| node/utrecht-sneller-slim-melden | utrecht-sneller-slim-melden | node-utrecht-sneller-slim-melden | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/TradingAgents | TradingAgents | python-tradingagents | python | unknown | uv | TauricResearch | external | - | - | - | - | - | - | - | - | - | - | - |
| python/activitywatch-report | activitywatch-report | python-activitywatch-report | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/agenda-scraper | agenda-scraper | python-agenda-scraper | python | unknown | uv | doublej | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| python/ai-hedge-fund | ai-hedge-fund | python-ai-hedge-fund | python | unknown | uv | virattt | external | - | - | - | - | - | - | - | - | - | - | - |
| python/aider-agent | aider-agent | python-aider-agent | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/airplay-to-ipad | airplay-to-ipad | python-airplay-to-ipad | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/algoalpa | algoalpa | python-algoalpa | python | unknown | uv | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| python/amsterdam-house-data | amsterdam-house-data | python-amsterdam-house-data | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/apple-notes-sync | apple-notes-sync | python-apple-notes-sync | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/associator | associator | python-associator | python | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/aw-client | aw-client | python-aw-client | python | unknown | - | ActivityWatch | external | - | - | - | - | - | - | - | - | - | - | - |
| python/aw-watcher-agents | aw-watcher-agents | python-aw-watcher-agents | python | unknown | uv | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| python/better-input | better-input | python-better-input | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/binwatch | binwatch | python-binwatch | python | unknown | uv | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/boilerplate/test_project | test_project | python-boilerplate-test-project | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/boilerplate/{{cookiecutter.project_slug}} | {{cookiecutter.project_slug}} | python-boilerplate-cookiecutter-project-slug | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/claude-aider.archived | claude-aider.archived | python-claude-aider-archived | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/claude-code-telegram | claude-code-telegram | python-claude-code-telegram | python | unknown | uv | RichardAtCT | external | - | - | - | - | - | - | - | - | - | - | - |
| python/club-simulations | club-simulations | python-club-simulations | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/comfy-panohead | comfy-panohead | python-comfy-panohead | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/comfy-ui | comfy-ui | python-comfy-ui | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/cookiecutter-uv | cookiecutter-uv | python-cookiecutter-uv | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/create_post | create_post | python-create-post | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/deep-researcher | deep-researcher | python-deep-researcher | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/dock-unfreeze | dock-unfreeze | python-dock-unfreeze | python | unknown | uv | - | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| python/ezviz-analysis | ezviz-analysis | python-ezviz-analysis | node | unknown | bun | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/ezviz-fetch | ezviz-fetch | python-ezviz-fetch | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/ezviz_api | ezviz_api | python-ezviz-api | node | unknown | npm | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/handsfree | handsfree | python-handsfree | python | unknown | uv | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| python/home-network-cli | home-network-cli | python-home-network-cli | python | unknown | uv | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| python/human-in-loop-mcp | human-in-loop-mcp | python-human-in-loop-mcp | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/image-compressor | image-compressor | python-image-compressor | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/lastfm-scraper | lastfm-scraper | python-lastfm-scraper | python | unknown | uv | dbeley | external | - | - | - | - | - | - | - | - | - | - | - |
| python/macos-data-keeper | macos-data-keeper | python-macos-data-keeper | python | unknown | uv | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/mcp_interview | mcp_interview | python-mcp-interview | python | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/music-deep-research | music-deep-research | python-music-deep-research | python | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/nordvpn-cli-macos | nordvpn-cli-macos | python-nordvpn-cli-macos | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/osxphotos | osxphotos | python-osxphotos | python | unknown | uv | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| python/panes-vr | panes-vr | python-panes-vr | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/panes-vr-2 | panes-vr-2 | python-panes-vr-2 | node | unknown | bun | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/pano-native-components | pano-native-components | python-pano-native-components | rust | unknown | - | kawaiiDango | external | - | - | - | - | - | - | - | - | - | - | - |
| python/pdf-extract | pdf-extract | python-pdf-extract | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/personal-telegram-bot | personal-telegram-bot | python-personal-telegram-bot | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/pimpelmees-bot | pimpelmees-bot | python-pimpelmees-bot | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/pioneer-vsx528 | pioneer-vsx528 | python-pioneer-vsx528 | python | unknown | uv | - | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| python/prompt_builder | prompt_builder | python-prompt-builder | python | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/psd-gpt-upscale | psd-gpt-upscale | python-psd-gpt-upscale | python | unknown | uv | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/psp-timezone-viz | psp-timezone-viz | python-psp-timezone-viz | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/pyterm-cli | pyterm-cli | python-pyterm-cli | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/race-agent | race-agent | python-race-agent | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/redacted | redacted | python-redacted | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/redacted-v2 | redacted-v2 | python-redacted-v2 | python | unknown | - | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/reminders-bridge | reminders-bridge | python-reminders-bridge | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/repo-analysis | repo-analysis | python-repo-analysis | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/sagemcom-mcp | sagemcom-mcp | python-sagemcom-mcp | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/sagemcom-mcp-copy | sagemcom-mcp-copy | python-sagemcom-mcp-copy | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/samsung-tv-devmode | samsung-tv-devmode | python-samsung-tv-devmode | python | unknown | uv | - | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| python/shazam-export | shazam-export | python-shazam-export | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/simstew | simstew | python-simstew | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/soundlink | soundlink | python-soundlink | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/ss-image-processor | ss-image-processor | python-ss-image-processor | python | unknown | pnpm | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/steam-take-a-backseat | steam-take-a-backseat | python-steam-take-a-backseat | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/streamer-container | streamer-container | python-streamer-container | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/sudo_agent | sudo_agent | python-sudo-agent | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/sudo_prompt_writer | sudo_prompt_writer | python-sudo-prompt-writer | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/suno-prompt-writer | suno-prompt-writer | python-suno-prompt-writer | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/swapper | swapper | python-swapper | python | unknown | uv | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| python/telegram-dispatch | telegram-dispatch | python-telegram-dispatch | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/threads | threads | python-threads | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/ticketswap | ticketswap | python-ticketswap | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/tiktoken-mcp | tiktoken-mcp | python-tiktoken-mcp | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/trader | trader | python-trader | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/uttertype-poc | uttertype-poc | python-uttertype-poc | python | unknown | uv | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| python/venv-manager | venv-manager | python-venv-manager | python | unknown | - | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/vr-support-bot | vr-support-bot | python-vr-support-bot | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/vr-support-bot-v4 | vr-support-bot-v4 | python-vr-support-bot-v4 | python | streamlit | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| python/weddingwriter/weddingwriter | weddingwriter | python-weddingwriter-weddingwriter | python | unknown | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/wozpeiler | wozpeiler | python-wozpeiler | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| python/yolo-detect-input | yolo-detect-input | python-yolo-detect-input | python | unknown | uv | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/ziggo-modem | ziggo-modem | python-ziggo-modem | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| rust/better-video-buffer | better-video-buffer | rust-better-video-buffer | rust | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| rust/download-organizer | download-organizer | rust-download-organizer | rust | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| rust/offcloud | offcloud | rust-offcloud | rust | unknown | - | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| rust/vibecopter | vibecopter | rust-vibecopter | rust | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| shaders/obs | obs | shaders-obs | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/adblock-rust | adblock-rust | swift-iterm2-submodules-adblock-rust | node | unknown | npm | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/iterm2-companion-relay | iterm2-companion-relay | swift-iterm2-submodules-iterm2-companion-relay | node | unknown | npm | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/libgit2 | libgit2 | swift-iterm2-submodules-libgit2 | node | unknown | - | libgit2 | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/libsixel | libsixel | swift-iterm2-submodules-libsixel | node | unknown | - | saitoha | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/railroad_dsl | railroad_dsl | swift-iterm2-submodules-railroad-dsl | rust | unknown | - | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/tests/websocket | websocket | swift-iterm2-tests-websocket | node | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/snailscan | snailscan | swift-snailscan | python | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| video/video-tools/video/makegif_claude | makegif_claude | video-video-tools-video-makegif-claude | python | unknown | uv | doublej | trunk | - | - | - | - | - | - | - | - | - | - | - |
| video/video-tools/video/makegif_gemini | makegif_gemini | video-video-tools-video-makegif-gemini | python | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| web/amsterdam-house-data | amsterdam-house-data | web-amsterdam-house-data | python | unknown | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| web/damagereport | damagereport | web-damagereport | node | unknown | - | - | local | - | - | - | - | - | - | - | - | - | - | - |
| web/disco | disco | web-disco | node | vue | npm | Poolside-FM | external | - | - | - | - | - | - | - | - | - | - | - |
| web/prompt-explorer-qwen/frontend | frontend | web-prompt-explorer-qwen-frontend | node | vue | npm | - | - | - | - | - | - | - | - | - | - | - | - | - |
| web/thunderbird-send-later | thunderbird-send-later | web-thunderbird-send-later | node | unknown | npm | - | local | - | - | - | - | - | - | - | - | - | - | - |
| web/webgl-shaft | webgl-shaft | web-webgl-shaft | node | unknown | - | - | local | - | - | - | - | - | - | - | - | - | - | - |

## python-service (10)

| path | name | slug | type | framework | runner | git owner | flow | justfile | pkg dev/start | port | hostname | .atlas | candidate | tier | nested | hardcodedPort | slugDup | slugLong |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| _sandbox/finances | finances | sandbox-finances | python | fastapi | uv | - | local | serve: `uv run uvicorn finances.main:app --reload --host 127.0.0.1 --port 8000` | - | - | - | - | - | - | - | 8000 | - | - |
| _sandbox/template-version-demo | template-version-demo | sandbox-template-version-demo | python | fastapi | - | - | - | dev: `uv run uvicorn template_version_demo.main:app --reload` | - | - | - | - | - | - | - | - | - | - |
| python/discover-siargao | discover-siargao | python-discover-siargao | python | fastapi | uv | - | - | dev: `uv run uvicorn discover_siargao.main:app --reload` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/fb-scrape | fb-scrape | python-fb-scrape | python | unknown | uv | doublej | trunk | dev: `cd api && uv run uvicorn main:app --reload --port 8000 & \` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | 8000 | - | - |
| python/funda-scraper-scrapling | funda-scraper-scrapling | python-funda-scraper-scrapling | python | fastapi | uv | doublej | trunk | dev: `uv run uvicorn listings_api.api:app --reload --host 0.0.0.0 --port 8000` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | 8000 | - | - |
| python/plume | plume | python-plume | python | fastapi | uv | - | local | dev: `uv run uvicorn plume.main:app --reload` | - | - | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/poolsuite-partners-invoice-generator | poolsuite-partners-invoice-generator | python-poolsuite-partners-invoice-generator | python | fastapi | uv | doublej | trunk | dev: `uv run uvicorn app.main:app --reload --port {{port}}`, run: `uv run python run.py`, start: `./start.sh` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/rig-toolkit | rig-toolkit | python-rig-toolkit | python | fastapi | uv | doublej | trunk | dev: `uv run uvicorn rig_toolkit.main:app --reload` | - | - | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/schakelwerk | schakelwerk | python-schakelwerk | python | fastapi | uv | doublej | trunk | dev: `onenv run -- uv run uvicorn schakelwerk.main:app --reload` | - | - | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| video/kfcut | kfcut | video-kfcut | python | fastapi | uv | - | local | dev: `uv run uvicorn kfcut.main:app --reload --port 8770` | - | 8770 | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | 8770 | - | - |

## unknown (41)

| path | name | slug | type | framework | runner | git owner | flow | justfile | pkg dev/start | port | hostname | .atlas | candidate | tier | nested | hardcodedPort | slugDup | slugLong |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| _management/cookiecutter-templates | cookiecutter-templates | management-cookiecutter-templates | generic | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| _management/disk | disk | management-disk | generic | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| _management/homenetwork | homenetwork | management-homenetwork | generic | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| go/bpr | bpr | go-bpr | go | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| go/iricco | iricco | go-iricco | go | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| go/portainer-mcp | portainer-mcp | go-portainer-mcp | go | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/byoc | byoc | multi-stack-byoc | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/claude-verbs | claude-verbs | multi-stack-claude-verbs | workspace | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/haist | haist | multi-stack-haist | workspace | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/homeassistant | homeassistant | multi-stack-homeassistant | workspace | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/project-atlas | project-atlas | multi-stack-project-atlas | workspace | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/simsync-marketing | simsync-marketing | multi-stack-simsync-marketing | workspace | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| multi-stack/utty | utty | multi-stack-utty | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/atomictype | atomictype | python-atomictype | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| python/ccom-repo | ccom-repo | python-ccom-repo | generic | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| python/whisper-app-v2/BuildedApp | BuildedApp | python-whisper-app-v2-buildedapp | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/whisper-app-v2/app | app | python-whisper-app-v2-app | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/ShellVox | ShellVox | swift-shellvox | swift | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| swift/browser-router | browser-router | swift-browser-router | swift | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| swift/dev-services | dev-services | swift-dev-services | swift | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| swift/dexam | dexam | swift-dexam | swift | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| swift/firstthingsfirst | firstthingsfirst | swift-firstthingsfirst | swift | unknown | - | - | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| swift/focus | focus | swift-focus | swift | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| swift/hostage | hostage | swift-hostage | generic | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| swift/imaketherules | imaketherules | swift-imaketherules | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/input-level-snitch | input-level-snitch | swift-input-level-snitch | swift | unknown | - | - | - | - | - | - | - | yes | - | - | - | - | - | - |
| swift/iterm2/Companion/CompanionCore | CompanionCore | swift-iterm2-companion-companioncore | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/WebExtensionsFramework | WebExtensionsFramework | swift-iterm2-webextensionsframework | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/cc-status | cc-status | swift-iterm2-cc-status | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/it2cli | it2cli | swift-iterm2-it2cli | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/pwmplugin | pwmplugin | swift-iterm2-pwmplugin | swift | unknown | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/BTree | BTree | swift-iterm2-submodules-btree | swift | unknown | - | attaswift | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/Highlightr | Highlightr | swift-iterm2-submodules-highlightr | swift | unknown | - | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/SFSymbolEnum | SFSymbolEnum | swift-iterm2-submodules-sfsymbolenum | swift | unknown | - | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/SwiftyMarkdown | SwiftyMarkdown | swift-iterm2-submodules-swiftymarkdown | swift | unknown | - | gnachman | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/iterm2/submodules/fmdb | fmdb | swift-iterm2-submodules-fmdb | swift | unknown | - | ccgus | external | - | - | - | - | - | - | - | - | - | - | - |
| swift/riliv | riliv | swift-riliv | swift | unknown | - | doublej | trunk | - | - | - | - | yes | - | - | - | - | - | - |
| swift/stt-ui-components | stt-ui-components | swift-stt-ui-components | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| swift/trackture | trackture | swift-trackture | swift | unknown | - | doublej | gitflow | - | - | - | - | yes | - | - | - | - | - | - |
| web/evensteven | evensteven | web-evensteven | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |
| web/repowiki | repowiki | web-repowiki | workspace | unknown | - | - | local | - | - | - | - | yes | - | - | - | - | - | - |

## web-dev-server (272)

| path | name | slug | type | framework | runner | git owner | flow | justfile | pkg dev/start | port | hostname | .atlas | candidate | tier | nested | hardcodedPort | slugDup | slugLong |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| _management/caveman-compress | caveman-compress | management-caveman-compress | node | unknown | bun | doublej | trunk | - | dev: `bun tsc --watch`, start: `bun ./src/index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/claude-history-browser | claude-history-browser | management-claude-history-browser | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5181 | - | - |
| _management/claude-summarizer-gemma | claude-summarizer-gemma | management-claude-summarizer-gemma | node | react | bun | - | - | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/cookiecutter-picker | cookiecutter-picker | management-cookiecutter-picker | node | unknown | bun | doublej | trunk | - | start: `bun run src/cli.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/kanban-claude | kanban-claude | management-kanban-claude | node | unknown | bun | doublej | trunk | - | start: `bun run index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/mcpick-plugins | mcpick-plugins | management-mcpick-plugins | node | unknown | bun | doublej | trunk | - | dev: `bun tsc --watch`, start: `bun ./dist/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/mcpick-plus | mcpick-plus | management-mcpick-plus | node | unknown | bun | doublej | trunk | - | dev: `bun tsc --watch`, start: `bun ./dist/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _management/strandkanban | strandkanban | management-strandkanban | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev --host` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| _sandbox/broken_ball | broken_ball | sandbox-broken-ball | node | vite | npm | - | - | - | dev: `vite` | - | - | - | - | - | - | 5199 | - | - |
| _sandbox/buurtpuzzelmap | buurtpuzzelmap | sandbox-buurtpuzzelmap | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | - | - | - | 5173 | - | - |
| _sandbox/clouds | clouds | sandbox-clouds | node | vite | bun | - | local | - | dev: `vite` | - | - | - | - | - | - | 5180 | - | - |
| _sandbox/csm-mlx | csm-mlx | sandbox-csm-mlx | python | fastapi | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/fractal-issue/rig-toolkit | rig-toolkit | sandbox-fractal-issue-rig-toolkit | python | fastapi | uv | - | - | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/homeassistant/guest-ui | guest-ui | sandbox-homeassistant-guest-ui | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | - | - | - | - | - | - |
| _sandbox/homebrew-tracker | homebrew-tracker | sandbox-homebrew-tracker | node | react | bun | - | - | - | dev: `vite` | - | - | - | - | - | - | 5173 | - | - |
| _sandbox/music | music | sandbox-music | node | unknown | bun | - | local | - | dev: `bun run src/cli.ts` | - | - | - | - | - | - | - | - | - |
| _sandbox/phone-finder | phone-finder | sandbox-phone-finder | node | svelte | bun | - | - | dev: `uv run python server.py & bun run dev` | dev: `vite` | - | - | - | - | - | - | 5173 | - | - |
| _sandbox/photoshop-mcp/server | server | sandbox-photoshop-mcp-server | node | unknown | npm | - | - | - | start: `node server.mjs` | - | - | - | - | - | - | - | - | - |
| _sandbox/pkgscan | pkgscan | sandbox-pkgscan | node | unknown | bun | - | - | - | start: `bun index.ts` | - | - | - | - | - | - | - | - | - |
| _sandbox/project-data | project-data | sandbox-project-data | node | unknown | npm | - | local | - | dev: `npm run watch:css & python3 -m http.server 8000` | - | - | - | - | - | - | - | - | - |
| _sandbox/render-keepalive | render-keepalive | sandbox-render-keepalive | node | unknown | - | - | - | - | start: `node index.js` | - | - | - | - | - | - | - | - | - |
| _sandbox/screencapture | screencapture | sandbox-screencapture | node | unknown | - | doublej | trunk | run: `bun run server.mjs` | dev: `bun run server.mjs`, start: `bun run server.mjs` | - | - | - | - | - | - | - | - | - |
| _sandbox/vanmoofs3 | vanmoofs3 | sandbox-vanmoofs3 | python | flask | uv | - | local | - | - | - | - | - | - | - | - | - | - | - |
| _sandbox/villa-onepager | villa-onepager | sandbox-villa-onepager | node | react | bun | - | - | - | dev: `vite` | - | - | - | - | - | - | - | - | - |
| _sandbox/vr-video-wall/svelte-app | svelte-app | sandbox-vr-video-wall-svelte-app | node | svelte | bun | - | - | - | dev: `vite --host` | - | - | - | - | - | - | - | - | - |
| _sandbox/vr-video-wall2/svelte-app | svelte-app | sandbox-vr-video-wall2-svelte-app | node | svelte | bun | - | - | - | dev: `vite --host` | - | - | - | - | - | - | - | - | - |
| _sandbox/vr-video-wall2/svelte-app_2 | svelte-app_2 | sandbox-vr-video-wall2-svelte-app-2 | node | svelte | bun | - | - | - | dev: `vite --host` | - | - | - | - | - | - | - | - | - |
| app/poolsuite | poolsuite | app-poolsuite | node | sveltekit | bun | - | gitflow | dev: `bun run dev` | dev: `vite dev --port 4107` | 4107 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4107 | - | - |
| app/youtube-music | youtube-music | app-youtube-music | node | electron | bun | th-ch | external | - | start: `electron-vite preview`, dev: `cross-env NODE_OPTIONS=--enable-source-maps electron-vite dev --watch` | - | - | - | - | - | - | - | - | - |
| audio/call-center-caller-companion | call-center-caller-companion | audio-call-center-caller-companion | python | fastapi | uv | - | local | dev: `@echo "Run 'just backend' and 'just frontend' in separate terminals"` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| games/spplx | spplx | games-spplx | node | sveltekit | bun | - | gitflow | dev: `bun run dev` | dev: `vite dev --port 4110` | 4110 | yes | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4110 | - | - |
| mcp/channels | channels | mcp-channels | node | unknown | bun | - | local | dev: `` | dev: `bun --cwd server hub.ts & bun --cwd ui webui.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| mcp/consult-user-mcp | consult-user-mcp | mcp-consult-user-mcp | node | unknown | bun | doublej | trunk | dev: `bun run dev` | dev: `bash scripts/dev-install.sh`, start: `cd mcp-server && bun run start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| mcp/mcp_agent_mail | mcp_agent_mail | mcp-mcp-agent-mail | python | fastapi | uv | Dicklesworthstone | external | - | - | - | - | - | - | - | - | - | - | - |
| misc/TheOcularMigraineMCP | TheOcularMigraineMCP | misc-theocularmigrainemcp | node | svelte | bun | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| misc/claude-agent-for-thunderbird | claude-agent-for-thunderbird | misc-claude-agent-for-thunderbird | node | elysia | bun | - | - | dev: `bun run dev`, start: `bun run start` | dev: `tsx watch src/index.ts`, start: `node dist/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| misc/cui | cui | misc-cui | node | sveltekit | bun | wbopan | external | dev: `@echo "🔗 Auth URL: http://localhost:5173#token=$(cat ~/.cui/config.json | grep authToken | cut -d'"' -f4)"` | dev: `vite dev` | - | - | - | - | - | - | 5173 | - | - |
| misc/telegram_bot | telegram_bot | misc-telegram-bot | node | express | npm | - | - | - | - | - | - | - | yes | T5 (candidate but no clear dev/start script or justfile recipe (runner=npm)) | - | - | - | - |
| misc/watermark-washer | watermark-washer | misc-watermark-washer | node | unknown | npm | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| multi-stack/flights | flights | multi-stack-flights | node | unknown | bun | doublej | trunk | dev: `cd apps/web && bun run dev` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/frameclarity | frameclarity | multi-stack-frameclarity | rust | tauri | - | doublej | trunk | dev: `cd apps/desktop && cargo tauri dev` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/framelink/app | app | multi-stack-framelink-app | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| multi-stack/framelink/app-worktrees/build-wiring | build-wiring | multi-stack-framelink-app-worktrees-build-wiring | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/cbrf-layout-gate | cbrf-layout-gate | multi-stack-framelink-app-worktrees-cbrf-layout-gate | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/config-path-lazy-derived | config-path-lazy-derived | multi-stack-framelink-app-worktrees-config-path-lazy-derived | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/config-path-seam | config-path-seam | multi-stack-framelink-app-worktrees-config-path-seam | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/debug-push-timeout | debug-push-timeout | multi-stack-framelink-app-worktrees-debug-push-timeout | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/dock-insert | dock-insert | multi-stack-framelink-app-worktrees-dock-insert | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/fixed-canvas-window | fixed-canvas-window | multi-stack-framelink-app-worktrees-fixed-canvas-window | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/flows-skip-and-hook | flows-skip-and-hook | multi-stack-framelink-app-worktrees-flows-skip-and-hook | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/legs-critical-flows | legs-critical-flows | multi-stack-framelink-app-worktrees-legs-critical-flows | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/lint-dead-imports | lint-dead-imports | multi-stack-framelink-app-worktrees-lint-dead-imports | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/pack-kernel-test | pack-kernel-test | multi-stack-framelink-app-worktrees-pack-kernel-test | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/pose-math-selftest | pose-math-selftest | multi-stack-framelink-app-worktrees-pose-math-selftest | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/quest-environments | quest-environments | multi-stack-framelink-app-worktrees-quest-environments | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/supervisor-expected-exit | supervisor-expected-exit | multi-stack-framelink-app-worktrees-supervisor-expected-exit | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/sysprops-and-rig-quoting | sysprops-and-rig-quoting | multi-stack-framelink-app-worktrees-sysprops-and-rig-quoting | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/uqb5 | uqb5 | multi-stack-framelink-app-worktrees-uqb5 | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/app-worktrees/vdd-preflight | vdd-preflight | multi-stack-framelink-app-worktrees-vdd-preflight | node | unknown | bun | doublej | trunk | - | start: `bun run start.ts` | - | - | - | - | - | - | - | - | - |
| multi-stack/framelink/auth | auth | multi-stack-framelink-auth | node | unknown | bun | doublej | trunk | - | dev: `wrangler dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| multi-stack/framelink/broker | broker | multi-stack-framelink-broker | node | unknown | bun | doublej | trunk | - | dev: `wrangler dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| multi-stack/framelink/homepage | homepage | multi-stack-framelink-homepage | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev --port 5175` | 5175 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 5175 | - | - |
| multi-stack/haist-payload | haist-payload | multi-stack-haist-payload | workspace | unknown | - | doublej | gitflow | dev: `#!/usr/bin/env bash` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/pimpelmees | pimpelmees | multi-stack-pimpelmees | workspace | unknown | - | - | local | dev: `#!/usr/bin/env bash` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/psp-assistants | psp-assistants | multi-stack-psp-assistants | node | elysia | bun | doublej | trunk | dev: `bun run dev`, start: `bun run start` | dev: `bun --watch src/index.ts`, start: `bun src/index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| multi-stack/redline | redline | multi-stack-redline | workspace | unknown | - | - | gitflow | dev: `#!/usr/bin/env zsh` | - | 4105 | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/remotevr | remotevr | multi-stack-remotevr | rust | tauri | - | - | local | run: `cargo run -p rvr-service` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/sideload | sideload | multi-stack-sideload | workspace | unknown | - | - | gitflow | dev: `cd web && bun run dev` | - | 4108 | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| multi-stack/simsync-mono | simsync-mono | multi-stack-simsync-mono | node | unknown | bun | doublej | trunk | dev: `#!/usr/bin/env bash` | dev: `bun run --cwd apps/worker dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/beads-sdk | beads-sdk | node-beads-sdk | node | unknown | bun | - | local | - | dev: `bun --watch src/index.ts` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/caddyctl | caddyctl | node-caddyctl | node | unknown | bun | doublej | trunk | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/cc-screenshots | cc-screenshots | node-cc-screenshots | node | unknown | bun | - | local | - | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/claude-activity-watcher | claude-activity-watcher | node-claude-activity-watcher | node | react | bun | doublej | trunk | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/ezviz-flasher | ezviz-flasher | node-ezviz-flasher | node | unknown | bun | - | local | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/ezviz-history-downloader | ezviz-history-downloader | node-ezviz-history-downloader | node | unknown | bun | - | - | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/group-chat-bud | group-chat-bud | node-group-chat-bud | node | elysia | bun | doublej | gitflow | dev: `onenv run -- bun run dev`, start: `onenv run -- bun run start` | dev: `bun --watch src/index.ts`, start: `bun src/index.ts` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/iracing-bbg | iracing-bbg | node-iracing-bbg | node | unknown | bun | - | - | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/jj-cms | jj-cms | node-jj-cms | node | next | bun | - | local | dev: `bun run dev` | dev: `next dev --turbopack` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/jj-cms-svelte | jj-cms-svelte | node-jj-cms-svelte | node | sveltekit | bun | doublej | trunk | dev: `` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/onenv | onenv | node-onenv | node | unknown | bun | doublej | trunk | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/payload | payload | node-payload | node | next | pnpm | payloadcms | external | - | dev: `cross-env NODE_OPTIONS="--no-deprecation --max-old-space-size=16384" tsx ./test/dev.ts` | - | - | - | - | - | - | - | - | - |
| node/picnic-cli | picnic-cli | node-picnic-cli | node | unknown | bun | - | - | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/pixi-devtools-cli | pixi-devtools-cli | node-pixi-devtools-cli | node | unknown | - | doublej | trunk | - | dev: `tsc --watch`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/poolsuite-cli | poolsuite-cli | node-poolsuite-cli | node | react | bun | doublej | trunk | - | start: `bun run src/index.ts`, dev: `bun run src/index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/process-watcher | process-watcher | node-process-watcher | node | unknown | bun | - | local | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/qbittorrent-cli | qbittorrent-cli | node-qbittorrent-cli | node | unknown | bun | - | - | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/qnap-cli | qnap-cli | node-qnap-cli | node | unknown | bun | doublej | trunk | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/rotary | rotary | node-rotary | node | hono | bun | - | local | dev: `bun run dev` | dev: `bun --watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/sheet-cms | sheet-cms | node-sheet-cms | node | elysia | bun | doublej | trunk | dev: `bun run dev`, start: `bun run start` | dev: `tsx watch src/server.ts`, start: `node dist/server.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/spotify-api-proxy | spotify-api-proxy | node-spotify-api-proxy | node | unknown | - | - | - | dev: `bun run dev`, start: `bun run start` | dev: `tsx watch src/index.ts`, start: `node dist/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/troostwijk-auction-tools | troostwijk-auction-tools | node-troostwijk-auction-tools | node | unknown | bun | doublej | trunk | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| node/umami-cli | umami-cli | node-umami-cli | node | unknown | bun | - | local | dev: `bun run dev` | dev: `tsx watch src/cli.ts`, start: `node dist/cli.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/bank-parser-python | bank-parser-python | python-bank-parser-python | python | fastapi | - | doublej | trunk | - | - | - | - | - | yes | T5 (candidate but no clear dev/start script or justfile recipe (runner=None)) | - | - | - | - |
| python/cancel-services/nodejs-bank-parser | nodejs-bank-parser | python-cancel-services-nodejs-bank-parser | node | express | npm | - | - | - | dev: `npm run shared:build && tsx watch src/index.ts`, start: `node dist/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/ccusage | ccusage | python-ccusage | node | hono | bun | ryoppippi | external | - | start: `bun run ./src/index.ts` | - | - | - | - | - | - | - | - | - |
| python/disk-usage-macos/reclaim | reclaim | python-disk-usage-macos-reclaim | python | fastapi | uv | doublej | trunk | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/dj-mix-builder | dj-mix-builder | python-dj-mix-builder | workspace | unknown | - | doublej | trunk | dev: `@if tmux has-session -t {{_session}} 2>/dev/null; then \` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| python/finances | finances | python-finances | python | fastapi | uv | doublej | gitflow | dev: `#!/usr/bin/env bash` | - | 8000 | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/follow_caps | follow_caps | python-follow-caps | python | unknown | uv | - | local | run: `uv run --python /opt/homebrew/opt/python@3.13/bin/python3.13 poc.py` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/gokova-flights | gokova-flights | python-gokova-flights | python | fastapi | uv | AWeirdDev | external | - | - | - | - | - | - | - | - | - | - | - |
| python/haist-qr | haist-qr | python-haist-qr | node | svelte | npm | doublej | trunk | - | dev: `vite --port 3749` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3749 | - | - |
| python/haist-qr-web | haist-qr-web | python-haist-qr-web | node | svelte | npm | - | local | - | dev: `vite --port 5174` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5174 | - | - |
| python/haist-qr-web-shadcn | haist-qr-web-shadcn | python-haist-qr-web-shadcn | node | svelte | npm | doublej | trunk | - | dev: `vite --port 5174` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5174 | - | - |
| python/hyndsyght | hyndsyght | python-hyndsyght | python | fastapi | uv | - | local | - | - | - | - | yes | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/micstream | micstream | python-micstream | python | fastapi | uv | - | - | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/parakeet-server | parakeet-server | python-parakeet-server | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/pimpelmees-bot-v2 | pimpelmees-bot-v2 | python-pimpelmees-bot-v2 | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/playlist-researcher | playlist-researcher | python-playlist-researcher | python | fastapi | uv | doublej | trunk | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/playlistbuilder | playlistbuilder | python-playlistbuilder | python | fastapi | uv | doublej | gitflow | dev: `uv run playlist-migrator web` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/playlistbuilder-node | playlistbuilder-node | python-playlistbuilder-node | node | hono | bun | - | local | - | dev: `bun run build && ./bin/run.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/poolsuite-radio-cast | poolsuite-radio-cast | python-poolsuite-radio-cast | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/project-estimation | project-estimation | python-project-estimation | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/project-middleware | project-middleware | python-project-middleware | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/psp-timezone-viz-v2 | psp-timezone-viz-v2 | python-psp-timezone-viz-v2 | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/report-ai-music | report-ai-music | python-report-ai-music | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/scraper | scraper | python-scraper | node | unknown | npm | - | - | - | dev: `motia dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/shazamap | shazamap | python-shazamap | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/sim-map-sync | sim-map-sync | python-sim-map-sync | python | fastapi | uv | python | external | - | - | - | - | - | - | - | - | - | - | - |
| python/snail-mail-parser | snail-mail-parser | python-snail-mail-parser | python | fastapi | uv | doublej | trunk | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/snail-mail-parser-2026/backend | backend | python-snail-mail-parser-2026-backend | python | fastapi | uv | - | - | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/snail-mail-parser-2026/frontend | frontend | python-snail-mail-parser-2026-frontend | node | sveltekit | bun | - | - | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/suna/suna/backend | backend | python-suna-suna-backend | python | fastapi | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| python/suna/suna/frontend | frontend | python-suna-suna-frontend | node | next | npm | - | - | - | dev: `next dev`, start: `next start` | - | - | - | - | - | - | - | - | - |
| python/uttertype | uttertype | python-uttertype | node | unknown | uv | doublej | gitflow | dev: `#!/usr/bin/env bash` | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/utty | utty | python-utty | swift | unknown | - | doublej | trunk | dev: `#!/usr/bin/env zsh` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| python/vibecopter | vibecopter | python-vibecopter | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/vibecopter-v2 | vibecopter-v2 | python-vibecopter-v2 | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/video-capture-to-slides | video-capture-to-slides | python-video-capture-to-slides | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| python/vr_support_bot_2 | vr_support_bot_2 | python-vr-support-bot-2 | python | fastapi | uv | - | - | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| python/weddingwriter/demo-free-layout | demo-free-layout | python-weddingwriter-demo-free-layout | node | react | npm | - | - | - | dev: `cross-env MODE=app NODE_ENV=development rsbuild dev --open`, start: `cross-env NODE_ENV=development rsbuild dev --open` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/claude-code-raycast-projects/claude-code-launcher | claude-code-launcher | raycast-claude-code-raycast-projects-claude-code-launcher | node | unknown | npm | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/gif-search | gif-search | raycast-gif-search | node | unknown | npm | - | local | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-active-ports | raycast-ext-active-ports | raycast-raycast-ext-active-ports | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-caddyfile-tools | raycast-ext-caddyfile-tools | raycast-raycast-ext-caddyfile-tools | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-caveman-compress | raycast-ext-caveman-compress | raycast-raycast-ext-caveman-compress | node | unknown | npm | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-claude-history | raycast-ext-claude-history | raycast-raycast-ext-claude-history | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-clean-text | raycast-ext-clean-text | raycast-raycast-ext-clean-text | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-clean-watermark | raycast-ext-clean-watermark | raycast-raycast-ext-clean-watermark | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-file-scripts | raycast-ext-file-scripts | raycast-raycast-ext-file-scripts | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-fix-text | raycast-ext-fix-text | raycast-raycast-ext-fix-text | node | unknown | bun | - | local | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-hide-my-email | raycast-ext-hide-my-email | raycast-raycast-ext-hide-my-email | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-insecure-chrome | raycast-ext-insecure-chrome | raycast-raycast-ext-insecure-chrome | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-keyboard-backlight | raycast-ext-keyboard-backlight | raycast-raycast-ext-keyboard-backlight | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-openrouter-key | raycast-ext-openrouter-key | raycast-raycast-ext-openrouter-key | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-text-tools | raycast-ext-text-tools | raycast-raycast-ext-text-tools | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-wake-pc | raycast-ext-wake-pc | raycast-raycast-ext-wake-pc | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| raycast/raycast-ext-wrap-text | raycast-ext-wrap-text | raycast-raycast-ext-wrap-text | node | unknown | bun | doublej | trunk | - | dev: `ray develop` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| rust/alvr-webui | alvr-webui | rust-alvr-webui | node | react | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| swift/battery-sitter | battery-sitter | swift-battery-sitter | swift | unknown | - | doublej | trunk | run: `swift run BatterySitter` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/claude-code-configurator | claude-code-configurator | swift-claude-code-configurator | swift | unknown | - | doublej | trunk | run: `swift run ClaudeCodeConfigurator` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/consult-user-sketch | consult-user-sketch | swift-consult-user-sketch | node | unknown | bun | doublej | trunk | - | start: `node mcp-server/dist/index.js` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| swift/continuity | continuity | swift-continuity | swift | swiftui | - | doublej | gitflow | run: `#!/usr/bin/env zsh` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/home | home | swift-home | swift | unknown | - | doublej | trunk | run: `xcrun devicectl device process launch --device {{ device_id }} {{ bundle_id }}` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/iterm2/Companion/PushRelay | PushRelay | swift-iterm2-companion-pushrelay | node | unknown | npm | - | - | - | start: `node bin/push-relay.js` | - | - | - | - | - | - | - | - | - |
| swift/keyspose | keyspose | swift-keyspose | swift | unknown | - | - | - | run: `swift run KeySpose` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/mermaid-watching | mermaid-watching | swift-mermaid-watching | swift | unknown | - | - | local | run: `open .build/app/Mermaid\ Watching.app` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/notchbr | notchbr | swift-notchbr | swift | unknown | - | - | - | run: `swift run NotchBr` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/slds | slds | swift-slds | swift | unknown | - | doublej | trunk | run: `swift run Slds` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| swift/utt | utt | swift-utt | swift | swiftui | - | doublej | trunk | run: `#!/usr/bin/env zsh` | - | - | - | yes | yes | T3 (just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling) | - | - | - | - |
| web/711heatmap | 711heatmap | web-711heatmap | node | svelte | bun | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/MAHORAGA | MAHORAGA | web-mahoraga | node | unknown | npm | doublej | trunk | - | dev: `wrangler dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/airbnb-guest-ui | airbnb-guest-ui | web-airbnb-guest-ui | node | next | bun | doublej | trunk | dev: `bun run dev` | dev: `next dev`, start: `next start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/assetto-corsa-evo-replay-visualizer | assetto-corsa-evo-replay-visualizer | web-assetto-corsa-evo-replay-visualizer | node | vite | bun | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/ccom/docs | docs | web-ccom-docs | node | sveltekit | bun | - | - | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/claude-code-prompt-composer | claude-code-prompt-composer | web-claude-code-prompt-composer | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/club-positioning | club-positioning | web-club-positioning | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/create_li_post | create_li_post | web-create-li-post | node | react | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| web/demo-voor-klip | demo-voor-klip | web-demo-voor-klip | node | sveltekit | - | - | - | dev: `bun run dev` | dev: `vite dev --port 4100` | 4100 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4100 | - | - |
| web/dorsman-co | dorsman-co | web-dorsman-co | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/dotcomt-shirtscom | dotcomt-shirtscom | web-dotcomt-shirtscom | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/doublej-project-linking | doublej-project-linking | web-doublej-project-linking | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/doublej/nav | nav | web-doublej-nav | node | unknown | - | - | - | - | dev: `wrangler dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/eink | eink | web-eink | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | 4109 | yes | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | - | - | - |
| web/element-filter | element-filter | web-element-filter | node | vite | npm | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| web/estimate_delivery/estimate-delivery-react | estimate-delivery-react | web-estimate-delivery-estimate-delivery-react | node | express | npm | - | - | - | start: `node server.js`, dev: `nodemon server.js & browser-sync start --proxy localhost:3000 --files '**/*.css, **/*.html, **/*.js' --no-notify` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/festival-timetable | festival-timetable | web-festival-timetable | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `bunx --bun vite dev --port 5180`, start: `bun ./build/index.js` | 5180 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 5180 | - | - |
| web/fflawwwards | fflawwwards | web-fflawwwards | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/fileupload/backend | backend | web-fileupload-backend | node | express | npm | - | - | - | - | - | - | - | yes | T5 (candidate but no clear dev/start script or justfile recipe (runner=npm)) | - | - | - | - |
| web/fileupload/frontend | frontend | web-fileupload-frontend | node | vue | npm | - | - | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/fractal | fractal | web-fractal | node | sveltekit | npm | - | local | - | dev: `vite dev --port 4173` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 4173 | - | - |
| web/fuddhism | fuddhism | web-fuddhism | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/fuddhism-nextjs | fuddhism-nextjs | web-fuddhism-nextjs | node | next | - | doublej | trunk | dev: `bun run dev` | dev: `next dev --turbopack`, start: `next start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/gemeente | gemeente | web-gemeente | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/github-trend-watch | github-trend-watch | web-github-trend-watch | node | sveltekit | bun | - | local | start: `bun run dev`, dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/globe | globe | web-globe | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/glow | glow | web-glow | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev --host` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/gta-vreeswijk | gta-vreeswijk | web-gta-vreeswijk | node | vite | bun | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/haist | haist | web-haist | node | react | npm | Yannickgregoire | external | - | dev: `vite` | - | - | - | - | - | - | - | - | - |
| web/haist-v2/frontend | frontend | web-haist-v2-frontend | node | svelte | bun | - | - | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5173 | - | - |
| web/image-effect-renderer | image-effect-renderer | web-image-effect-renderer | node | svelte | bun | - | local | dev: `bun run dev` | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/info-map-view | info-map-view | web-info-map-view | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5173 | - | - |
| web/iphone-mirror-eu | iphone-mirror-eu | web-iphone-mirror-eu | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/iracing-planner | iracing-planner | web-iracing-planner | node | express | npm | - | local | - | start: `node app.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/jamesexpress | jamesexpress | web-jamesexpress | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 48173 | - | - |
| web/jurrejan | jurrejan | web-jurrejan | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/koh-lanta-bike-rental | koh-lanta-bike-rental | web-koh-lanta-bike-rental | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/libgen-downloader | libgen-downloader | web-libgen-downloader | node | react | bun | doublej | trunk | - | start: `bun run src/index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/llm-clipboard-bridge | llm-clipboard-bridge | web-llm-clipboard-bridge | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/lowlands-weather | lowlands-weather | web-lowlands-weather | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev --port 4104` | 4104 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4104 | - | - |
| web/marktplaats/backend | backend | web-marktplaats-backend | node | unknown | bun | - | - | - | dev: `bun --watch src/index.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/marktplaats/docs | docs | web-marktplaats-docs | node | sveltekit | bun | - | - | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/marktplaats/frontend | frontend | web-marktplaats-frontend | node | sveltekit | bun | - | - | - | dev: `bun --bun vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/matching-masters | matching-masters | web-matching-masters | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/mermaid-gantt | mermaid-gantt | web-mermaid-gantt | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/midjourney-prompt-builder | midjourney-prompt-builder | web-midjourney-prompt-builder | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev --port 5190` | 5190 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 5190 | - | - |
| web/minority | minority | web-minority | node | react | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| web/monotyco | monotyco | web-monotyco | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 49173 | - | - |
| web/mosquito-trap | mosquito-trap | web-mosquito-trap | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/msn-messenger | msn-messenger | web-msn-messenger | python | fastapi | uv | - | local | - | - | - | - | - | yes | T4 (python-service / uv runner: atlas injects nothing, port must come from the app itself) | - | - | - | - |
| web/npo-dl-fresh | npo-dl-fresh | web-npo-dl-fresh | node | unknown | bun | doublej | trunk | - | start: `node src/server/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/obs-remote | obs-remote | web-obs-remote | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/offerte | offerte | web-offerte | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 47333 | - | - |
| web/payment-links | payment-links | web-payment-links | node | next | npm | - | local | - | dev: `next dev -p 3456`, start: `next start -p 3456` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/personal-homepage | personal-homepage | web-personal-homepage | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/personal-homepage-simple | personal-homepage-simple | web-personal-homepage-simple | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev --port 4101` | 4101 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4101 | - | - |
| web/personal-www-2 | personal-www-2 | web-personal-www-2 | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5173 | - | - |
| web/personal-www-2 - 1 | personal-www-2 - 1 | web-personal-www-2-1 | node | sveltekit | npm | - | - | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/personal-www-v3 | personal-www-v3 | web-personal-www-v3 | node | sveltekit | npm | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/photoshop-image-gpt-2-plugin | photoshop-image-gpt-2-plugin | web-photoshop-image-gpt-2-plugin | node | unknown | - | - | local | - | start: `onenv run -- node server/index.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/pimpelgram | pimpelgram | web-pimpelgram | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/pixi-paper | pixi-paper | web-pixi-paper | node | vite | npm | doublej | trunk | - | dev: `vite --port 5847` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5847 | - | - |
| web/pixijs-debug | pixijs-debug | web-pixijs-debug | node | vite | bun | - | local | - | start: `bun run --filter '*' start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite-playlist-prompter | poolsuite-playlist-prompter | web-poolsuite-playlist-prompter | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev --host` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/agency | agency | web-poolsuite-agency | node | next | bun | Poolside-FM | external | - | dev: `next dev`, start: `next start` | - | - | - | - | - | - | - | - | - |
| web/poolsuite/pixi-adaptive-glass | pixi-adaptive-glass | web-poolsuite-pixi-adaptive-glass | node | vite | bun | doublej | trunk | - | dev: `vite --config vite.config.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5173 | - | - |
| web/poolsuite/pixi-filter-refraction | pixi-filter-refraction | web-poolsuite-pixi-filter-refraction | node | unknown | bun | - | local | - | dev: `tsup src/index.ts --format cjs,esm --dts --watch` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/pixi-v8_glass | pixi-v8_glass | web-poolsuite-pixi-v8-glass | node | vite | npm | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3001 | - | - |
| web/poolsuite/pixi-v8_glass_codex | pixi-v8_glass_codex | web-poolsuite-pixi-v8-glass-codex | node | vite | npm | - | local | - | dev: `vite --host` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5173 | - | - |
| web/poolsuite/pixi-v8_glass_from_example | pixi-v8_glass_from_example | web-poolsuite-pixi-v8-glass-from-example | node | vite | npm | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/poolsuite-pager | poolsuite-pager | web-poolsuite-poolsuite-pager | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/psp_website | psp_website | web-poolsuite-psp-website | node | next | npm | - | local | - | dev: `next dev -p 3877`, start: `next start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/silentsongs_alt | silentsongs_alt | web-poolsuite-silentsongs-alt | node | vite | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 9009 | - | - |
| web/poolsuite/ss_glass2 | ss_glass2 | web-poolsuite-ss-glass2 | node | vite | bun | doublej | trunk | - | dev: `vite --config demo/vite.config.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/poolsuite/two-point-o/psp-20 | psp-20 | web-poolsuite-two-point-o-psp-20 | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev --port 4103` | 4103 | - | yes | - | - | - | 4103 | - | - |
| web/prettygoodtime | prettygoodtime | web-prettygoodtime | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev --port 5193` | 5193 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 5193 | - | - |
| web/psp-network | psp-network | web-psp-network | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/psp-shapes | psp-shapes | web-psp-shapes | node | express | bun | doublej | trunk | - | start: `node save-server.js`, dev: `concurrently "node save-server.js" "node puppeteer-server.js"` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/realtor-photo-preview | realtor-photo-preview | web-realtor-photo-preview | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/sarahmaximclub | sarahmaximclub | web-sarahmaximclub | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/segment-display | segment-display | web-segment-display | node | vite | bun | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5183 | - | - |
| web/shader-pipe | shader-pipe | web-shader-pipe | node | vue | npm | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/shader-poolsuite-partners-logo | shader-poolsuite-partners-logo | web-shader-poolsuite-partners-logo | node | vite | npm | - | local | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 33891 | - | - |
| web/shader-videoplayer-lekkerbellen | shader-videoplayer-lekkerbellen | web-shader-videoplayer-lekkerbellen | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/siargao-market | siargao-market | web-siargao-market | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/siargao-weather | siargao-weather | web-siargao-weather | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5891 | - | - |
| web/smoke | smoke | web-smoke | node | react | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/snackbar | snackbar | web-snackbar | node | unknown | npm | - | local | - | start: `http-server .` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/soundcloud-api-test | soundcloud-api-test | web-soundcloud-api-test | node | svelte | npm | - | local | - | dev: `node server.js & vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5174 | - | - |
| web/spoofy | spoofy | web-spoofy | node | sveltekit | - | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/ss-glass | ss-glass | web-ss-glass | node | vite | bun | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| web/ss-glass-module | ss-glass-module | web-ss-glass-module | node | vite | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 3000 | - | - |
| web/story-generator | story-generator | web-story-generator | node | vite | bun | - | - | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/substack | substack | web-substack | node | sveltekit | bun | doublej | trunk | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/svgocial | svgocial | web-svgocial | node | sveltekit | bun | - | local | - | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/terminal | terminal | web-terminal | node | unknown | bun | - | local | - | start: `node src/server/server.js`, dev: `node --watch src/server/server.js` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/terminal-emulator | terminal-emulator | web-terminal-emulator | node | unknown | npm | doublej | trunk | - | dev: `concurrently "npm run dev:backend" "npm run dev:frontend"`, start: `npm run start:backend` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/the-ultimate-music-quiz | the-ultimate-music-quiz | web-the-ultimate-music-quiz | node | unknown | bun | doublej | gitflow | dev: `bun run dev` | dev: `concurrently --kill-others "bun run --filter tumq-worker dev" "bun run --filter client dev"`, start: `bun run --filter server start` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/travel-days | travel-days | web-travel-days | node | svelte | npm | doublej | trunk | - | dev: `vite` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/trending-feed | trending-feed | web-trending-feed | python | flask | - | doublej | trunk | - | - | - | - | - | yes | T5 (candidate but no clear dev/start script or justfile recipe (runner=None)) | - | - | - | - |
| web/turkey_spend | turkey_spend | web-turkey-spend | node | express | npm | doublej | trunk | - | dev: `vite --port 8765` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 8765 | - | - |
| web/uitgelegd.info | uitgelegd.info | web-uitgelegd-info | node | nuxt | bun | duvigneau | external | - | dev: `nuxt dev` | - | - | - | - | - | - | - | - | - |
| web/umami | umami | web-umami | node | next | pnpm | doublej | trunk | - | dev: `dotenv next dev --turbo`, start: `next start` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/umbrella | umbrella | web-umbrella | node | sveltekit | npm | - | local | - | dev: `vite dev --port 5847` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | 5847 | - | - |
| web/unsubscribe-sanctuary | unsubscribe-sanctuary | web-unsubscribe-sanctuary | node | sveltekit | bun | - | gitflow | dev: `bun run dev` | dev: `vite dev --port 4106` | 4106 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4106 | - | - |
| web/unsubscribe/app | app | web-unsubscribe-app | node | sveltekit | bun | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/unsubscribe/automation-server | automation-server | web-unsubscribe-automation-server | node | unknown | bun | - | - | dev: `@if tmux has-session -t unsub-srv 2>/dev/null; then \` | dev: `HEADFUL=1 bun run src/server.ts`, start: `bun run src/server.ts` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/utt-website | utt-website | web-utt-website | node | sveltekit | bun | - | local | dev: `bun run dev` | dev: `vite dev --port 4102` | 4102 | - | yes | yes | T1 (node runner with dev/start script and an .atlas port on record) | - | 4102 | - | - |
| web/utty-website | utty-website | web-utty-website | node | sveltekit | - | - | - | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/vibecopter-v3 | vibecopter-v3 | web-vibecopter-v3 | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/wallgen | wallgen | web-wallgen | node | nuxt | - | - | - | - | dev: `nuxt dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/webglmask-crosspage-test | webglmask-crosspage-test | web-webglmask-crosspage-test | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | - | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |
| web/wildeburg-timetable | wildeburg-timetable | web-wildeburg-timetable | node | sveltekit | bun | doublej | trunk | dev: `bun run dev` | dev: `vite dev` | - | - | yes | yes | T2 (node runner with dev/start script but no .atlas port yet — first run will allocate one) | - | - | - | - |

## Notes: unclassified or anomalous

- swift/firstthingsfirst: type=swift framework=unknown no port/scripts/justfile signal
- swift/trackture: type=swift framework=unknown no port/scripts/justfile signal
- _management/homenetwork: type=generic framework=unknown no port/scripts/justfile signal
- multi-stack/project-atlas: type=workspace framework=unknown no port/scripts/justfile signal
- _management/cookiecutter-templates: type=generic framework=unknown no port/scripts/justfile signal
- go/bpr: type=go framework=unknown no port/scripts/justfile signal
- python/whisper-app-v2/app: type=swift framework=unknown no port/scripts/justfile signal
- swift/imaketherules: type=swift framework=unknown no port/scripts/justfile signal
- swift/riliv: type=swift framework=unknown no port/scripts/justfile signal
- swift/ShellVox: type=swift framework=unknown no port/scripts/justfile signal
- swift/browser-router: type=swift framework=unknown no port/scripts/justfile signal
- swift/focus: type=swift framework=unknown no port/scripts/justfile signal
- swift/dexam: type=swift framework=unknown no port/scripts/justfile signal
- swift/input-level-snitch: type=swift framework=unknown no port/scripts/justfile signal
- swift/dev-services: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/pwmplugin: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/WebExtensionsFramework: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/cc-status: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/it2cli: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/Companion/CompanionCore: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/submodules/Highlightr: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/submodules/SwiftyMarkdown: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/submodules/fmdb: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/submodules/SFSymbolEnum: type=swift framework=unknown no port/scripts/justfile signal
- swift/iterm2/submodules/BTree: type=swift framework=unknown no port/scripts/justfile signal
- go/iricco: type=go framework=unknown no port/scripts/justfile signal
- multi-stack/simsync-marketing: type=workspace framework=unknown no port/scripts/justfile signal
- _management/disk: type=generic framework=unknown no port/scripts/justfile signal
- python/ccom-repo: type=generic framework=unknown no port/scripts/justfile signal
- web/evensteven: type=workspace framework=unknown no port/scripts/justfile signal
- swift/stt-ui-components: type=workspace framework=unknown no port/scripts/justfile signal
- swift/hostage: type=generic framework=unknown no port/scripts/justfile signal
- go/portainer-mcp: type=go framework=unknown no port/scripts/justfile signal
- multi-stack/utty: type=workspace framework=unknown no port/scripts/justfile signal
- multi-stack/claude-verbs: type=workspace framework=unknown no port/scripts/justfile signal
- multi-stack/homeassistant: type=workspace framework=unknown no port/scripts/justfile signal
- multi-stack/haist: type=workspace framework=unknown no port/scripts/justfile signal
- multi-stack/byoc: type=workspace framework=unknown no port/scripts/justfile signal
- python/atomictype: type=workspace framework=unknown no port/scripts/justfile signal
- web/repowiki: type=workspace framework=unknown no port/scripts/justfile signal
- python/whisper-app-v2/BuildedApp: type=swift framework=unknown no port/scripts/justfile signal
