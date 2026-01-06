---
applyTo: '**'
---
# Basic Instructions

- Always respond in Japasese.
- 常に日本語で回答すること。

# Comment Format

Always written in Japanese.
When you write comments in Japanese, follow the following rules:
- である調、または体言止めで書くこと。
- 各行の末尾に「。」をつけないこと。
When generating Swift code, strictly adhere to the following documentation comment format to ensure compatibility with Xcode's Quick Help and code completion.

## 1. General Principles
- Provide documentation comments for all public `classes`, `structs`, `enums`, `protocols`, `methods`, and `properties`.
- Use the `///` (triple-slash) delimiter with Markdown formatting.
- The first line must be a concise "Summary." Add a blank line before providing a more detailed description if necessary.

## 2. Method Formatting
When generating methods, include the following structured fields:
- **Summary**: A brief description of what the method does.
- **Parameters**: List each parameter name followed by its description.
- **Returns**: Describe the value returned by the method.
- **Throws**: Describe the conditions under which the method throws an error (if applicable).

### Example:
/// Creates a greeting message for a specific user.
///
/// This section provides detailed implementation notes or usage requirements.
/// - Parameters:
///   - name: The name of the person to greet.
///   - age: The age of the person.
/// - Returns: A formatted string containing the greeting.
func createGreeting(name: String, age: Int) -> String

## 3. Type Formatting (struct/class/enum)
- Provide a brief overview of the type's responsibility.
- Document individual properties using `///` to explain their purpose or constraints.

### Example:
/// A data model representing a user's profile information.
struct UserProfile {
    /// The unique identifier stored in the database.
    let id: UUID
    /// The display name. Must not be empty.
    var displayName: String
}

## 4. Special Callouts
Use the following callouts to highlight important information:
- `- Note:` Important supplemental information.
- `- Warning:` Critical usage warnings or safety risks.
- `- Example:` Follow with a code block to show how to use the API.

---
Follow these guidelines to produce high-quality, readable code that integrates perfectly with Xcode's developer tools.
