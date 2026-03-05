// Package generate provides code generation directives for the Fizzy SDK.
//
// Run `go generate ./...` from the go directory to regenerate the client code.
//
//go:generate go tool oapi-codegen -config oapi-codegen.yaml ../openapi.json
package generate
