# Swift build and test environment
FROM swift:6.0-jammy

WORKDIR /app

# Install SQLite dev files (required for CSQLite)
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire project
COPY . .

# Build the project
RUN swift build

# Run tests
RUN swift test
