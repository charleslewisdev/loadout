# Reviewer: tests and failure handling

Judge whether the tests prove the change, and whether failures stay visible.

- For each behavior the change adds or alters, find the test that covers it. Name the case no test covers, for example a boundary or an error path, and the input that would expose a bug there.
- Look for tests that cannot fail: assertions on mocks alone, a condition that is always true, a caught exception that passes the test.
- Look for failures swallowed in the changed code: empty `except` or `catch`, errors logged and dropped, a fallback value that hides a broken input.

Return each finding as: file and line, the gap in one sentence, and the input or state that would slip through, and a severity: Blocking, Should fix or Consider.
