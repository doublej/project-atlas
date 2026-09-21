# Project Atlas — build & install all components

# Build and install everything
all: api browser picker disk

# atlas-api: install deps + type-check
api:
    cd atlas-api && bun install && bun run check

# atlas-browser: install deps + build Raycast extension
browser:
    cd atlas-browser && bun install && npm run build

# atlas-picker: lint + fmt-check + release build + install to ~/.cargo/bin
picker:
    cd atlas-picker && just reinstall

# atlas-disk: lint + fmt-check + release build + install to ~/.cargo/bin
disk:
    cd atlas-disk && just reinstall
