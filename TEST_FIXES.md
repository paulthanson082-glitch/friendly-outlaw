# Test Fixes for PR #525 Regression

## Overview
This document addresses test failures introduced by PR #525 and provides fixes to restore test stability and coverage.

## Identified Test Failures

### 1. Authentication Tests
**Issue:** Mock authentication provider not properly reset between tests
**Fix:** Implement proper setUp/tearDown in test lifecycle

```swift
class AuthenticationTests: XCTestCase {
    var authManager: AuthenticationManager!
    var mockProvider: MockAuthProvider!
    
    override func setUp() {
        super.setUp()
        mockProvider = MockAuthProvider()
        authManager = AuthenticationManager(provider: mockProvider)
    }
    
    override func tearDown() {
        authManager = nil
        mockProvider = nil
        super.tearDown()
    }
    
    func testLoginSuccess() {
        mockProvider.shouldSucceed = true
        authManager.login(username: "test", password: "pass")
        XCTAssertTrue(authManager.isAuthenticated)
    }
}
```

### 2. API Client Tests
**Issue:** Network calls not properly mocked, causing flaky tests
**Fix:** Use URLSession mock with predefined responses

```swift
class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    var urlSession: URLSession!
    
    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: config)
        apiClient = APIClient(session: urlSession)
    }
    
    func testFetchUserData() async throws {
        MockURLProtocol.mockResponseData = validUserJSON
        let user = try await apiClient.fetchUser(id: "123")
        XCTAssertEqual(user.id, "123")
    }
}
```

### 3. View Model Tests
**Issue:** State changes not properly awaited in async tests
**Fix:** Use async/await with proper task completion

```swift
class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    
    @MainActor
    func testUserDataLoading() async {
        viewModel = UserViewModel()
        let expectation = XCTestExpectation(description: "Data loaded")
        
        Task {
            await viewModel.loadUser()
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(viewModel.user)
    }
}
```

### 4. Database Tests
**Issue:** Database state persisting across test runs
**Fix:** Use in-memory database for testing

```swift
class DatabaseTests: XCTestCase {
    var database: Database!
    
    override func setUp() {
        super.setUp()
        // Use in-memory SQLite for tests
        database = Database(inMemory: true)
    }
    
    func testUserInsert() throws {
        try database.insertUser(User(id: "1", name: "Test"))
        let users = try database.fetchUsers()
        XCTAssertEqual(users.count, 1)
    }
}
```

### 5. Snapshot Tests
**Issue:** Snapshot files not updated after UI changes
**Fix:** Regenerate snapshots with verification

```swift
class SnapshotTests: XCTestCase {
    func testHomeViewSnapshot() {
        let view = HomeView()
        assertSnapshot(matching: view, as: .image)
    }
}
```

## Test Utilities

### Mock Helpers
```swift
class MockAPIProvider: APIProviderProtocol {
    var lastRequest: URLRequest?
    var mockResponse: Data?
    var shouldFail = false
    
    func request(_ request: URLRequest) async throws -> Data {
        lastRequest = request
        if shouldFail {
            throw APIError.networkFailure
        }
        return mockResponse ?? Data()
    }
}
```

### Async Test Helpers
```swift
extension XCTestCase {
    func waitForAsync(_ closure: @escaping () async -> Void) async {
        await closure()
    }
    
    func asyncTest(_ closure: @escaping () async throws -> Void) -> (() throws -> Void) {
        return { try runAsyncTest(closure) }
    }
}
```

## CI/CD Integration

Update test pipeline to run all test suites:

```yaml
test:
  script:
    - xcodebuild test -scheme FriendlyOutlaw -destination 'platform=iOS'
    - swiftlint
    - xcov report
```

## Test Coverage Requirements

- Unit tests: 80%+ coverage
- Integration tests: Key user flows
- Snapshot tests: UI components

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Tests timeout | Async operations not awaited | Use async/await with timeout |
| Flaky API tests | Real network calls | Mock URLSession |
| State pollution | Shared test state | Reset in setUp/tearDown |
| Snapshot mismatches | UI changes | Verify and regenerate |

## Running Tests

```bash
# All tests
xcodebuild test -scheme FriendlyOutlaw

# Specific test class
xcodebuild test -scheme FriendlyOutlaw \
  -only-testing FriendlyOutlawTests/AuthenticationTests

# With code coverage
xcodebuild test -scheme FriendlyOutlaw \
  -enableCodeCoverage YES
```

## Next Steps

1. Run full test suite to identify remaining failures
2. Fix infrastructure-related issues (mock setup)
3. Update snapshots after confirmed UI changes
4. Increase coverage to 80% threshold
5. Add integration tests for critical flows
