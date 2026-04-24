# Swift build, test, and run environment for WritersApp.
#
# Usage:
#   docker build -f Dockerfile.swift -t friendly-outlaw:swift .
#   docker run --rm -it friendly-outlaw:swift            # runs the CLI
#   docker run --rm friendly-outlaw:swift swift test     # runs the test suite
#
# Pass your Anthropic key for AI features:
#   docker run --rm -it -e ANTHROPIC_API_KEY=sk-ant-... friendly-outlaw:swift

FROM swift:6.0-jammy AS builder

# System deps required by CSQLite (pkgConfig: "sqlite3")
RUN apt-get update && apt-get install -y --no-install-recommends \
        libsqlite3-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Resolve dependencies first so this layer caches across source edits.
COPY Package.swift Package.resolved* ./
RUN swift package resolve

# Copy the rest of the source and build + test in release mode.
COPY Sources ./Sources
COPY Tests ./Tests
RUN swift build -c release && swift test

# ---------- runtime ----------
FROM swift:6.0-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
        libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash writer

WORKDIR /app
COPY --from=builder /app/.build/release/WritersAppCLI /usr/local/bin/WritersAppCLI

USER writer
ENV WRITERSAPP_DB_PATH=/home/writer/writersapp.db
CMD ["WritersAppCLI"]
