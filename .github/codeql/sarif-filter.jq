# Strips generated-code results from CodeQL SARIF before upload.
# Single source of truth: codeql.yml applies this file with `jq -f`, and
# test-sarif-filter.sh asserts it against testdata/sarif-filter-fixture.json,
# so the test always exercises the exact program the workflow runs.
.runs |= map(.results |= (. // [] | map(
  select(
    (.locations // [])[0].physicalLocation.artifactLocation.uri // "" |
    test("(^|/)(go/pkg/generated/|typescript/(src/generated|dist)/|ruby/lib/fizzy/generated/|swift/Sources/Fizzy/Generated/|kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/generated/|rust/fizzy-sdk/src/generated/)") | not
  )
)))
