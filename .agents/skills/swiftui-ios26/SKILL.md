# SwiftUI iOS 26 Skill

## When to Load
Load this skill when:
- Using `@Observable` macro and Observation framework
- Implementing navigation with NavigationStack
- Working with Swift 6 strict concurrency
- Using new iOS 26 SwiftUI APIs

## @Observable vs ObservableObject

### Old Way (Don't Use)
```swift
class Store: ObservableObject {
    @Published var value = 0
}
// In View: @StateObject var store = Store()
```

### New Way (Use This)
```swift
@Observable
final class Store {
    var value = 0
}
// In View: @State var store = Store()
// Or from environment: @Environment(Store.self) var store
```

## Key Benefits of @Observable
- Fine-grained tracking (only re-renders views that access changed properties)
- No `@Published` wrappers needed
- Works with `@Environment` injection
- Better performance for large state objects

## Environment Injection Pattern

```swift
// In App
@main
struct MyApp: App {
    @State private var store = GameStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}

// In View
struct MyView: View {
    @Environment(GameStore.self) private var store
    
    var body: some View {
        Text("\(store.state.players.count)")
    }
}
```

## Swift 6 Strict Concurrency

### Sendable Types
```swift
struct Player: Sendable { ... }  // Value types usually fine
final class Store: Sendable { ... }  // Must be carefully designed
```

### @MainActor for UI State
```swift
@Observable
@MainActor
final class GameStore {
    var state: GameState
    
    func dispatch(_ action: GameAction) {
        // Safe to update UI state
    }
}
```

### Async Work Off Main Thread
```swift
func generateImage() {
    Task.detached(priority: .userInitiated) {
        let result = await heavyWork()
        await MainActor.run {
            self.state.image = result
        }
    }
}
```

## Navigation Patterns

### Simple Navigation
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(item.name, value: item)
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

### Programmatic Navigation
```swift
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    // ...
}

// To navigate:
path.append(someValue)

// To pop:
path.removeLast()
```

## FocusState for Keyboard Management

```swift
struct ClueInput: View {
    @FocusState private var isFocused: Bool
    @State private var text = ""
    
    var body: some View {
        TextField("Enter clue", text: $text)
            .focused($isFocused)
            .onAppear { isFocused = true }
    }
}
```

## Critical Research Notes (Section 14)

### Observation Framework Gotchas
- No nested `@Observable` objects issues in iOS 26.2
- Use `@IgnoreObservation` for properties that shouldn't trigger UI updates
- Fine-grained tracking means only accessed properties cause re-render
- Thread-safety ensured via `@MainActor` on store

### Navigation for Wizard Flows
Two approaches for multi-phase game flow:
1. **Phase-based switching** (recommended): Single view switches on `gamePhase`
2. **NavigationStack with path**: Programmatic push/pop

Phase-based is simpler and avoids navigation stack memory issues.

### Swift 6 Sendable Requirements
- Value types (structs) are usually `Sendable` automatically
- `@Observable` classes need careful design for `Sendable`
- `UIImage` is NOT Sendable - avoid sending across threads
- Use `@MainActor` to confine UI state mutations

### Performance Considerations
- One large `@Observable` GameStore is fine (Apple confirms efficient)
- Avoid heavy computations in view `body`
- Pre-compute derived data in reducer or computed properties
- Use `.equatable()` on views for frequent re-renders if needed

### Safe Array Access
Always use safe subscript to avoid crashes:
```swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```
