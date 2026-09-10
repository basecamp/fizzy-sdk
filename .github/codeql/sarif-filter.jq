# Strips generated-code results from CodeQL SARIF before upload.
# Single source of truth: codeql.yml applies this file with `jq -f`, and
# test-sarif-filter.sh asserts it against testdata/sarif-filter-fixture.json,
# so the test always exercises the exact program the workflow runs.
#
# Go has two generated locations: go/pkg/generated/ (oapi-codegen) and the
# *_service.go files plus operations_registry.go that go/cmd/generate-services
# writes into go/pkg/fizzy/ beside the hand-written runtime. The service
# pattern is anchored on the .go suffix so *_service_test.go, which is
# hand-written, stays.
.runs |= map(.results |= (. // [] | map(
  select(
    (.locations // [])[0].physicalLocation.artifactLocation.uri // "" |
    test("(^|/)(go/pkg/generated/|go/pkg/fizzy/([a-z_]+_service|operations_registry)\\.go$|typescript/(src/generated|dist)/|ruby/lib/fizzy/generated/|swift/Sources/Fizzy/Generated/|kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/generated/|rust/fizzy-sdk/src/generated/)") | not
  )
)))
