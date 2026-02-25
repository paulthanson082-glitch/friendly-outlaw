/** @type {import('jest').Config} */
const config = {
  projects: [
    // Node environment: lib utilities and API routes
    {
      displayName: "node",
      testEnvironment: "node",
      testMatch: [
        "<rootDir>/lib/__tests__/**/*.test.ts",
        "<rootDir>/app/api/**/__tests__/**/*.test.ts",
      ],
      transform: {
        "^.+\\.tsx?$": ["ts-jest", { tsconfig: { jsx: "react-jsx" } }],
      },
      moduleNameMapper: {
        "^@/(.*)$": "<rootDir>/$1",
      },
    },
    // jsdom environment: React components
    {
      displayName: "jsdom",
      testEnvironment: "jest-environment-jsdom",
      testMatch: ["<rootDir>/app/__tests__/**/*.test.tsx"],
      transform: {
        "^.+\\.tsx?$": ["ts-jest", { tsconfig: { jsx: "react-jsx" } }],
      },
      moduleNameMapper: {
        "^@/(.*)$": "<rootDir>/$1",
      },
      setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
    },
  ],
};

module.exports = config;
