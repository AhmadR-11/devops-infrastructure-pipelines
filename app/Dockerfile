# ---- Stage 1: Builder ----
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies to ensure no development tools/compilers are included
RUN npm install --omit=dev

# Copy the actual application source code
COPY src/ ./src/

# ---- Stage 2: Minimal Runtime ----
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy only the pre-installed production dependencies and source code from the builder stage
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/src ./src

# Change ownership of the files to the built-in non-root 'node' user
RUN chown -R node:node /usr/src/app

# Enforce running the container as a non-root user for security compliance
USER node

# Expose the application port
EXPOSE 3000

# Start the Node.js server
CMD ["node", "src/server.js"]
